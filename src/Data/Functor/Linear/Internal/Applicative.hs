{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_HADDOCK hide #-}

module Data.Functor.Linear.Internal.Applicative
  ( Applicative (..),
    genericPure,
    genericLiftA2,
  )
where

import qualified Control.Monad.Trans.Reader as NonLinear
import Data.Functor.Compose
import Data.Functor.Const
import Data.Functor.Identity
import Data.Functor.Linear.Internal.Functor
import Data.Functor.Product
import Data.Monoid (Ap (..))
import Data.Monoid.Linear hiding (Product)
import Data.Unrestricted.Linear.Internal.Ur (Ur (..))
import GHC.TypeLits
import GHC.Types
import Prelude.Linear.Generically
import Prelude.Linear.Internal
import Prelude.Linear.Unsatisfiable
import qualified Prelude

-- # Applicative definition
-------------------------------------------------------------------------------

-- | Data 'Applicative'-s can be seen as containers which can be zipped
-- together. A prime example of data 'Applicative' are vectors of known length
-- ('ZipList's would be, if it were not for the fact that zipping them together
-- drops values, which we are not allowed to do in a linear container).
--
-- In fact, an applicative functor is precisely a functor equipped with (pure
-- and) @liftA2 :: (a %1-> b %1-> c) -> f a %1-> f b %1-> f c@. In the case where
-- @f = []@, the signature of 'liftA2' would specialise to that of 'zipWith'.
--
-- Intuitively, the type of 'liftA2' means that 'Applicative's can be seen as
-- containers whose "number" of elements is known at compile-time. This
-- includes vectors of known length but excludes 'Maybe', since this may
-- contain either zero or one value.  Similarly, @((->) r)@ forms a Data
-- 'Applicative', since this is a (possibly infinitary) container indexed by
-- @r@, while lists do not, since they may contain any number of elements.
--
-- == Remarks for the mathematically inclined
--
-- An 'Applicative' is, as in the restricted case, a lax monoidal endofunctor of
-- the category of linear types. That is, it is equipped with
--
-- * a (linear) function @() %1-> f ()@
-- * a (linear) natural transformation @(f a, f b) %1-> f (a, b)@
--
-- It is a simple exercise to verify that these are equivalent to the definition
-- of 'Applicative'. Hence that the choice of linearity of the various arrow is
-- indeed natural.
class Functor f => Applicative f where
  {-# MINIMAL pure, (liftA2 | (<*>)) #-}
  pure :: a -> f a
  (<*>) :: f (a %1 -> b) %1 -> f a %1 -> f b
  infixl 4 <*> -- same fixity as base.<*>
  f <*> x = liftA2 ($) f x
  liftA2 :: (a %1 -> b %1 -> c) -> f a %1 -> f b %1 -> f c
  liftA2 f x y = f <$> x <*> y

-- # Instances
-------------------------------------------------------------------------------

deriving via
  Generically1 (Const x)
  instance
    Monoid x => Applicative (Const x)

deriving via
  Generically1 Ur
  instance
    Applicative Ur

deriving via
  Generically1 ((,) a)
  instance
    Monoid a => Applicative ((,) a)

deriving via
  Generically1 (Product (f :: Type -> Type) g)
  instance
    (Applicative f, Applicative g) => Applicative (Product f g)

deriving via
  Generically1 ((f :: Type -> Type) :*: g)
  instance
    (Applicative f, Applicative g) => Applicative (f :*: g)

deriving via
  Generically1 ((,,) a b)
  instance
    (Monoid a, Monoid b) => Applicative ((,,) a b)

deriving via
  Generically1 ((,,,) a b c)
  instance
    (Monoid a, Monoid b, Monoid c) => Applicative ((,,,) a b c)

deriving via
  Generically1 Identity
  instance
    Applicative Identity

instance (Applicative f, Applicative g) => Applicative (Compose f g) where
  pure x = Compose (pure (pure x))
  (Compose f) <*> (Compose x) = Compose (liftA2 (<*>) f x)
  liftA2 f (Compose x) (Compose y) = Compose (liftA2 (liftA2 f) x y)

instance Applicative m => Applicative (NonLinear.ReaderT r m) where
  pure x = NonLinear.ReaderT (\_ -> pure x)
  NonLinear.ReaderT f <*> NonLinear.ReaderT x = NonLinear.ReaderT (\r -> f r <*> x r)

instance (Applicative f, Semigroup a) => Semigroup (Ap f a) where
  (Ap x) <> (Ap y) = Ap $ liftA2 (<>) x y

instance (Applicative f, Monoid a) => Monoid (Ap f a) where
  mempty = Ap $ pure mempty

-- ----------------
-- Generic deriving
-- ----------------

instance
  (Generic1 f, Functor (Rep1 f), GApplicative ('ShowType f) (Rep1 f)) =>
  Applicative (Generically1 f)
  where
  pure = Generically1 Prelude.. genericPure
  liftA2 f (Generically1 x) (Generically1 y) = Generically1 (genericLiftA2 f x y)

genericPure ::
  forall f a.
  (Generic1 f, GApplicative ('ShowType f) (Rep1 f)) =>
  a ->
  f a
genericPure = to1 Prelude.. gpure @('ShowType f)

genericLiftA2 ::
  forall f a b c.
  (Generic1 f, GApplicative ('ShowType f) (Rep1 f)) =>
  (a %1 -> b %1 -> c) ->
  f a %1 ->
  f b %1 ->
  f c
genericLiftA2 f x y = to1 (gliftA2 @('ShowType f) f (from1 x) (from1 y))

class GApplicative (s :: ErrorMessage) f where
  gpure :: a -> f a
  gliftA2 :: (a %1 -> b %1 -> c) -> f a %1 -> f b %1 -> f c

instance
  Unsatisfiable
    ( 'Text "Cannot derive a data Applicative instance for"
        ':$$: s
        ':$$: 'Text "because empty types cannot implement pure."
    ) =>
  GApplicative s V1
  where
  gpure = unsatisfiable
  gliftA2 = unsatisfiable

instance GApplicative s U1 where
  gpure _ = U1
  gliftA2 _ U1 U1 = U1
  {-# INLINE gpure #-}
  {-# INLINE gliftA2 #-}

instance GApplicative s f => GApplicative s (M1 i c f) where
  gpure = M1 Prelude.. gpure @s
  gliftA2 f (M1 x) (M1 y) = M1 (gliftA2 @s f x y)
  {-# INLINE gpure #-}
  {-# INLINE gliftA2 #-}

instance GApplicative s Par1 where
  gpure = Par1
  gliftA2 f (Par1 x) (Par1 y) = Par1 (f x y)
  {-# INLINE gpure #-}
  {-# INLINE gliftA2 #-}

instance (GApplicative s f, Applicative g) => GApplicative s (f :.: g) where
  gpure = Comp1 Prelude.. gpure @s Prelude.. pure
  gliftA2 f (Comp1 x) (Comp1 y) = Comp1 (gliftA2 @s (liftA2 f) x y)
  {-# INLINE gpure #-}
  {-# INLINE gliftA2 #-}

instance (GApplicative s f, GApplicative s g) => GApplicative s (f :*: g) where
  gpure a = gpure @s a :*: gpure @s a
  gliftA2 f (a1 :*: a2) (b1 :*: b2) = gliftA2 @s f a1 b1 :*: gliftA2 @s f a2 b2
  {-# INLINE gpure #-}
  {-# INLINE gliftA2 #-}

instance
  Unsatisfiable
    ( 'Text "Cannot derive a data Applicative instance for"
        ':$$: s
        ':$$: 'Text "because sum types do not admit a uniform Applicative definition."
    ) =>
  GApplicative s (x :+: y)
  where
  gpure = unsatisfiable
  gliftA2 = unsatisfiable

instance GApplicative s f => GApplicative s (MP1 m f) where
  gpure a = MP1 (gpure @s a)
  gliftA2 f (MP1 a) (MP1 b) = MP1 (gliftA2 @s f a b)
  {-# INLINE gpure #-}
  {-# INLINE gliftA2 #-}

instance Monoid c => GApplicative s (K1 i c) where
  gpure _ = K1 mempty
  gliftA2 _ (K1 x) (K1 y) = K1 (x <> y)
  {-# INLINE gpure #-}
  {-# INLINE gliftA2 #-}

instance
  Unsatisfiable
    ( 'Text "Cannot derive a data Applicative instance for"
        ':$$: s
        ':$$: 'Text "because it contains one or more primitive unboxed fields."
        ':$$: 'Text "Such unboxed types lack canonical monoid operations."
    ) =>
  GApplicative s (URec a)
  where
  gpure = unsatisfiable
  gliftA2 = unsatisfiable
