{-# OPTIONS_GHC -Wno-orphans #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE TypeOperators #-}

-- | This module exports instances of Consumable, Dupable and Movable
--
-- We export instances in this module to avoid a circular dependence
-- and keep things clean. Movable depends on the defintion of Ur yet
-- many instances of Movable which we might have put in the module with
-- Movable depend on Ur. So, we just put the instances of Movable and the
-- other classes (for cleanness) in this module to avoid this dependence.
module Data.Unrestricted.Internal.Instances where

import Data.Unrestricted.Internal.Consumable
import Data.Unrestricted.Internal.Dupable
import Data.Unrestricted.Internal.Movable
import Data.Unrestricted.Internal.Ur
import qualified Data.Functor.Linear.Internal.Functor as Data
import qualified Data.Functor.Linear.Internal.Applicative as Data
import GHC.Generics
import GHC.Types hiding (Any)
import Data.Monoid.Linear
import Data.List.NonEmpty
import qualified Prelude
import qualified Unsafe.Linear as Unsafe
import Data.V.Linear ()
import Prelude.Linear.Internal ((&))

instance Consumable () where
  consume () = ()

instance Dupable () where
  dupV () = Data.pure ()

instance Movable () where
  move () = Ur ()

instance Consumable Bool where
  consume True = ()
  consume False = ()

instance Dupable Bool where
  dupV True = Data.pure True
  dupV False = Data.pure False

instance Movable Bool where
  move True = Ur True
  move False = Ur False

instance Consumable Int where
  -- /!\ 'Int#' is an unboxed unlifted data-types, therefore it cannot have any
  -- linear values hidden in a closure anywhere. Therefore it is safe to call
  -- non-linear functions linearly on this type: there is no difference between
  -- copying an 'Int#' and using it several times. /!\
  consume (I# i) = Unsafe.toLinear (\_ -> ()) i

instance Dupable Int where
  -- /!\ 'Int#' is an unboxed unlifted data-types, therefore it cannot have any
  -- linear values hidden in a closure anywhere. Therefore it is safe to call
  -- non-linear functions linearly on this type: there is no difference between
  -- copying an 'Int#' and using it several times. /!\
  dupV (I# i) = Unsafe.toLinear (\j -> Data.pure (I# j)) i
  dup2 (I# i) = Unsafe.toLinear (\j -> (I# j, I# j)) i

instance Movable Int where
  -- /!\ 'Int#' is an unboxed unlifted data-types, therefore it cannot have any
  -- linear values hidden in a closure anywhere. Therefore it is safe to call
  -- non-linear functions linearly on this type: there is no difference between
  -- copying an 'Int#' and using it several times. /!\
  move (I# i) = Unsafe.toLinear (\j -> Ur (I# j)) i

instance Consumable Double where
  -- /!\ 'Double#' is an unboxed unlifted data-types, therefore it cannot have any
  -- linear values hidden in a closure anywhere. Therefore it is safe to call
  -- non-linear functions linearly on this type: there is no difference between
  -- copying an 'Double#' and using it several times. /!\
  consume (D# i) = Unsafe.toLinear (\_ -> ()) i

instance Dupable Double where
  -- /!\ 'Double#' is an unboxed unlifted data-types, therefore it cannot have any
  -- linear values hidden in a closure anywhere. Therefore it is safe to call
  -- non-linear functions linearly on this type: there is no difference between
  -- copying an 'Double#' and using it several times. /!\
  dupV (D# i) = Unsafe.toLinear (\j -> Data.pure (D# j)) i
  dup2 (D# i) = Unsafe.toLinear (\j -> (D# j, D# j)) i

instance Movable Double where
  -- /!\ 'Double#' is an unboxed unlifted data-types, therefore it cannot have any
  -- linear values hidden in a closure anywhere. Therefore it is safe to call
  -- non-linear functions linearly on this type: there is no difference between
  -- copying an 'Double#' and using it several times. /!\
  move (D# i) = Unsafe.toLinear (\j -> Ur (D# j)) i

instance Consumable Char where
  consume (C# c) = Unsafe.toLinear (\_ -> ()) c

instance Dupable Char where
  dupV (C# c) = Unsafe.toLinear (\x -> Data.pure (C# x)) c
  dup2 (C# c) = Unsafe.toLinear (\x -> (C# x, C# x)) c

instance Movable Char where
  move (C# c) = Unsafe.toLinear (\x -> Ur (C# x)) c

instance Consumable Ordering where
  consume LT = ()
  consume GT = ()
  consume EQ = ()

instance Dupable Ordering where
  dup2 LT = (LT, LT)
  dup2 GT = (GT, GT)
  dup2 EQ = (EQ, EQ)

instance Movable Ordering where
  move LT = Ur LT
  move GT = Ur GT
  move EQ = Ur EQ

-- TODO: instances for longer primitive tuples

instance (Consumable a, Consumable b) => Consumable (a, b) where
  consume (a, b) = consume a `lseq` consume b

instance (Dupable a, Dupable b) => Dupable (a, b) where
  dupV (a, b) = (,) Data.<$> dupV a Data.<*> dupV b

instance (Movable a, Movable b) => Movable (a, b) where
  move (a, b) = (,) Data.<$> move a Data.<*> move b

instance (Consumable a, Consumable b, Consumable c) => Consumable (a, b, c) where
  consume (a, b, c) = consume a `lseq` consume b `lseq` consume c

instance (Dupable a, Dupable b, Dupable c) => Dupable (a, b, c) where
  dupV (a, b, c) = (,,) Data.<$> dupV a Data.<*> dupV b Data.<*> dupV c

instance (Movable a, Movable b, Movable c) => Movable (a, b, c) where
  move (a, b, c) = (,,) Data.<$> move a Data.<*> move b Data.<*> move c

instance Consumable a => Consumable (Prelude.Maybe a) where
  consume Prelude.Nothing = ()
  consume (Prelude.Just x) = consume x

instance Dupable a => Dupable (Prelude.Maybe a) where
  dupV Prelude.Nothing = Data.pure Prelude.Nothing
  dupV (Prelude.Just x) = Data.fmap Prelude.Just (dupV x)

instance Movable a => Movable (Prelude.Maybe a) where
  move (Prelude.Nothing) = Ur Prelude.Nothing
  move (Prelude.Just x) = Data.fmap Prelude.Just (move x)

instance (Consumable a, Consumable b) => Consumable (Prelude.Either a b) where
  consume (Prelude.Left a) = consume a
  consume (Prelude.Right b) = consume b

instance (Dupable a, Dupable b) => Dupable (Prelude.Either a b) where
  dupV (Prelude.Left a) = Data.fmap Prelude.Left (dupV a)
  dupV (Prelude.Right b) = Data.fmap Prelude.Right (dupV b)

instance (Movable a, Movable b) => Movable (Prelude.Either a b) where
  move (Prelude.Left a) = Data.fmap Prelude.Left (move a)
  move (Prelude.Right b) = Data.fmap Prelude.Right (move b)

instance Consumable a => Consumable [a] where
  consume [] = ()
  consume (a:l) = consume a `lseq` consume l

instance Dupable a => Dupable [a] where
  dupV [] = Data.pure []
  dupV (a:l) = (:) Data.<$> dupV a Data.<*> dupV l

instance Movable a => Movable [a] where
  move [] = Ur []
  move (a:l) = (:) Data.<$> move a Data.<*> move l

instance Consumable a => Consumable (NonEmpty a) where
  consume (x :| xs) = consume x `lseq` consume xs

instance Dupable a => Dupable (NonEmpty a) where
  dupV (x :| xs) = (:|) Data.<$> dupV x Data.<*> dupV xs

instance Movable a => Movable (NonEmpty a) where
  move (x :| xs) = (:|) Data.<$> move x Data.<*> move xs

instance Consumable (Ur a) where
  consume (Ur _) = ()

instance Dupable (Ur a) where
  dupV (Ur a) = Data.pure (Ur a)
  dup2 (Ur a) = (Ur a, Ur a)

instance Movable (Ur a) where
  move (Ur a) = Ur (Ur a)

instance Prelude.Functor Ur where
  fmap f (Ur a) = Ur (f a)

instance Prelude.Applicative Ur where
  pure = Ur
  Ur f <*> Ur x = Ur (f x)

instance Data.Functor Ur where
  fmap f (Ur a) = Ur (f a)

instance Data.Applicative Ur where
  pure = Ur
  Ur f <*> Ur x = Ur (f x)

instance Prelude.Foldable Ur where
  foldMap f (Ur x) = f x

instance Prelude.Traversable Ur where
  sequenceA (Ur x) = Prelude.fmap Ur x

-- Some stock instances
deriving instance Consumable a => Consumable (Sum a)
deriving instance Dupable a => Dupable (Sum a)
deriving instance Movable a => Movable (Sum a)
deriving instance Consumable a => Consumable (Product a)
deriving instance Dupable a => Dupable (Product a)
deriving instance Movable a => Movable (Product a)
deriving instance Consumable All
deriving instance Dupable All
deriving instance Movable All
deriving instance Consumable Any
deriving instance Dupable Any
deriving instance Movable Any

newtype MovableMonoid a = MovableMonoid a
  deriving (Prelude.Semigroup, Prelude.Monoid)

instance (Movable a, Prelude.Semigroup a) => Semigroup (MovableMonoid a) where
  MovableMonoid a <> MovableMonoid b = MovableMonoid (combine (move a) (move b))
    where combine :: Prelude.Semigroup a => Ur a %1-> Ur a %1-> a
          combine (Ur x) (Ur y) = x Prelude.<> y
instance (Movable a, Prelude.Monoid a) => Monoid (MovableMonoid a)


instance GConsumable V1 where
  gconsume = \case
instance GConsumable U1 where
  gconsume U1 = ()
instance (GConsumable f, GConsumable g) => GConsumable (f :+: g) where
  gconsume (L1 a) = gconsume a
  gconsume (R1 a) = gconsume a
instance (GConsumable f, GConsumable g) => GConsumable (f :*: g) where
  gconsume (a :*: b) = gconsume a `seqUnit` gconsume b
instance Consumable c => GConsumable (K1 i c) where
  gconsume (K1 c) = consume c
instance GConsumable f => GConsumable (M1 i t f) where
  gconsume (M1 a) = gconsume a

instance GDupable V1 where
  gdup2 = \case
instance GDupable U1 where
  gdup2 U1 = (U1, U1)
instance (GDupable f, GDupable g) => GDupable (f :+: g) where
  gdup2 (L1 a) = gdup2 a & \case (x, y) -> (L1 x, L1 y)
  gdup2 (R1 a) = gdup2 a & \case (x, y) -> (R1 x, R1 y)
instance (GDupable f, GDupable g) => GDupable (f :*: g) where
  gdup2 (a :*: b) = gdup2 a & \case
    (a1, a2) -> gdup2 b & \case
      (b1, b2) -> (a1 :*: b1, a2 :*: b2)
instance Dupable c => GDupable (K1 i c) where
  gdup2 (K1 c) = dup2 c & \case (x, y) -> (K1 x, K1 y)
instance GDupable f => GDupable (M1 i t f) where
  gdup2 (M1 a) = gdup2 a & \case (x, y) -> (M1 x, M1 y)

instance GMovable V1 where
  gmove = \case
instance GMovable U1 where
  gmove U1 = Ur U1
instance (GMovable f, GMovable g) => GMovable (f :+: g) where
  gmove (L1 a) = gmove a & \case (Ur x) -> Ur (L1 x)
  gmove (R1 a) = gmove a & \case (Ur x) -> Ur (R1 x)
instance (GMovable f, GMovable g) => GMovable (f :*: g) where
  gmove (a :*: b) = gmove a & \case
    (Ur x) -> gmove b & \case
      (Ur y) -> Ur (x :*: y)
instance Movable c => GMovable (K1 i c) where
  gmove (K1 c) = move c & \case (Ur x) -> Ur (K1 x)
instance GMovable f => GMovable (M1 i t f) where
  gmove (M1 a) = gmove a & \case (Ur x) -> Ur (M1 x)
