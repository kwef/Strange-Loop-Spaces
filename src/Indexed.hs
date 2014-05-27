{-# LANGUAGE ConstraintKinds      #-}
{-# LANGUAGE DataKinds            #-}
{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE UndecidableInstances #-}

module Indexed where

import Control.Comonad
import Control.Applicative
import Data.Functor.Identity
import Data.Functor.Compose

import Control.Lens ( view , over )
import Control.Lens.Tuple

import Tape
import Reference
import Nested
import CountedList
import Cartesian

type Coordinate n = CountedList n (Ref Absolute)

data Indexed ts a =
  Indexed { index     :: Coordinate (NestedCount ts)
          , unindexed :: Nested ts a }

instance (Functor (Nested ts)) => Functor (Indexed ts) where
   fmap f (Indexed i t) = Indexed i (fmap f t)

type Indexable ts = ( Cross (NestedCount ts) Tape , ts ~ NestedNTimes (NestedCount ts) Tape )

indices :: (Cross n Tape) => Coordinate n -> Nested (NestedNTimes n Tape) (Coordinate n)
indices = cross . fmap enumerate

instance (ComonadApply (Nested ts), Indexable ts) => Comonad (Indexed ts) where
   extract      = extract . unindexed
   duplicate it = Indexed (index it) $
                     Indexed <$> indices (index it)
                             <@> duplicate (unindexed it)

instance (ComonadApply (Nested ts), Indexable ts) => ComonadApply (Indexed ts) where
   (Indexed i fs) <@> (Indexed _ xs) = Indexed i (fs <@> xs)
