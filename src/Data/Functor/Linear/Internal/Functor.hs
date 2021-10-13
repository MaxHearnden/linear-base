{-# OPTIONS_HADDOCK hide #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE Trustworthy #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
module Data.Functor.Linear.Internal.Functor
  (
    Functor(..)
  , (<$>)
  , (<$)
  , void
  ) where

import Prelude.Linear.Internal
import Prelude (Maybe(..), Either(..))
import Data.Functor.Const
import Data.Functor.Sum
import Data.Functor.Compose
import qualified Control.Monad.Trans.Reader as NonLinear
import qualified Control.Monad.Trans.Cont as NonLinear
import qualified Control.Monad.Trans.Maybe as NonLinear
import qualified Control.Monad.Trans.Except as NonLinear
import qualified Control.Monad.Trans.State.Strict as Strict
import Data.Unrestricted.Internal.Consumable
import Generics.Linear
import Prelude.Linear.Generically
import Data.Unrestricted.Internal.Ur (Ur (..))
import qualified Unsafe.Linear as Unsafe
import Data.V.Linear.Internal.V (V (..))
import qualified Data.Vector as Vector
import Data.Functor.Identity (Identity (..))

-- # Functor definition
-------------------------------------------------------------------------------

-- | Linear Data Functors should be thought of as containers holding values of
-- type @a@ over which you are able to apply a linear function of type @a %1->
-- b@ __on each__ value of type @a@ in the functor and consume a given functor
-- of type @f a@.
class Functor f where
  fmap :: (a %1-> b) -> f a %1-> f b

(<$>) :: Functor f => (a %1-> b) -> f a %1-> f b
(<$>) = fmap

-- | Replace all occurances of @b@ with the given @a@
-- and consume the functor @f b@.
(<$) :: (Functor f, Consumable b) => a -> f b %1-> f a
a <$ fb = fmap (`lseq` a) fb

-- | Discard a consumable value stored in a data functor.
void :: (Functor f, Consumable a) => f a %1-> f ()
void = fmap consume

-- # Instances
-------------------------------------------------------------------------------

instance Functor [] where
  fmap _f [] = []
  fmap f (a:as) = f a : fmap f as

instance Functor (Const x) where
  fmap _ (Const x) = Const x

instance Functor Maybe where
  fmap _ Nothing = Nothing
  fmap f (Just x) = Just (f x)

instance Functor (Either e) where
  fmap _ (Left x) = Left x
  fmap f (Right x) = Right (f x)

deriving via Generically1 ((,) a)
  instance Functor ((,) a)

deriving via Generically1 ((,,) a b)
  instance Functor ((,,) a b)

deriving via Generically1 ((,,,) a b c)
  instance Functor ((,,,) a b c)

deriving via Generically1 ((,,,,) a b c d)
  instance Functor ((,,,,) a b c d)

deriving via Generically1 Identity
  instance Functor Identity

instance (Functor f, Functor g) => Functor (Sum f g) where
  fmap f (InL fa) = InL (fmap f fa)
  fmap f (InR ga) = InR (fmap f ga)

instance (Functor f, Functor g) => Functor (Compose f g) where
  fmap f (Compose x) = Compose (fmap (fmap f) x)

instance Functor Ur where
  fmap f (Ur a) = Ur (f a)

instance Functor (V n) where
  fmap f (V xs) = V $ Unsafe.toLinear (Vector.map (\x -> f x)) xs

---------------------------------
-- Monad transformer instances --
---------------------------------

instance Functor m => Functor (NonLinear.ReaderT r m) where
  fmap f (NonLinear.ReaderT g) = NonLinear.ReaderT (\r -> fmap f (g r))

-- The below transformers are all Data.Functors and all fail to be
-- Data.Applicatives without further restriction. In every case however,
-- @pure :: a -> f a@ can be defined in the standard way.
-- For @MaybeT@ and @ExceptT e@, the failure to be applicative is as detailed
-- above: @Maybe@ and @Either e@ can contain 0 or 1 elements, and so fail
-- to be applicative.
-- To give applicative instances for ContT (resp. StateT), we require the
-- parameter r (resp. s) to be Movable.

instance Functor m => Functor (NonLinear.MaybeT m) where
  fmap f (NonLinear.MaybeT x) = NonLinear.MaybeT $ fmap (fmap f) x

instance Functor m => Functor (NonLinear.ExceptT e m) where
  fmap f (NonLinear.ExceptT x) = NonLinear.ExceptT $ fmap (fmap f) x

instance Functor (NonLinear.ContT r m) where
  fmap f (NonLinear.ContT x) = NonLinear.ContT $ \k -> x (\a -> k (f a))

instance Functor m => Functor (Strict.StateT s m) where
  fmap f (Strict.StateT x) = Strict.StateT (\s -> fmap (\(a, s') -> (f a, s')) (x s))

------------------------
-- Generics instances --
------------------------
instance (Generic1 f, Functor (Rep1 f)) => Functor (Generically1 f) where
  fmap f = Generically1 . to1 . fmap f . from1 . unGenerically1

instance Functor U1 where
  fmap _ U1 = U1
instance Functor V1 where
  fmap _ = \case
instance (Functor f, Functor g) => Functor (f :*: g) where
  fmap f (l :*: r) = fmap f l :*: fmap f r
instance (Functor f, Functor g) => Functor (f :+: g) where
  fmap f (L1 a) = L1 (fmap f a)
  fmap f (R1 a) = R1 (fmap f a)
instance Functor (K1 i v) where
  fmap _ (K1 c) = K1 c
instance Functor f => Functor (M1 i c f) where
  fmap f (M1 a) = M1 (fmap f a)
instance Functor Par1 where
  fmap f (Par1 a) = Par1 (f a)
instance (Functor f, Functor g) => Functor (f :.: g) where
  fmap f (Comp1 a) = Comp1 (fmap (fmap f) a)
instance Functor f => Functor (MP1 m f) where
  fmap f (MP1 x) = MP1 (fmap f x)
