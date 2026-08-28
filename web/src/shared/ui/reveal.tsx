'use client';

import { motion, useReducedMotion, type Variants } from 'motion/react';
import { useEffect, useState, type ComponentProps } from 'react';

const EASE_OUT = [0.16, 1, 0.3, 1] as const;
const VIEWPORT = { amount: 0.18, once: true } as const;

const REVEAL_VARIANTS = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    transition: { duration: 0.62, ease: EASE_OUT },
    y: 0,
  },
} satisfies Variants;

const STAGGER_VARIANTS = {
  hidden: {},
  visible: {
    transition: { delayChildren: 0.08, staggerChildren: 0.1 },
  },
} satisfies Variants;

const STAGGER_ITEM_VARIANTS = {
  hidden: { opacity: 0, y: 16 },
  visible: {
    opacity: 1,
    transition: { duration: 0.56, ease: EASE_OUT },
    y: 0,
  },
} satisfies Variants;

type RevealProps = Omit<
  ComponentProps<typeof motion.div>,
  'initial' | 'variants' | 'viewport' | 'whileInView'
>;

type RevealGroupProps = RevealProps;

type RevealListProps = Omit<
  ComponentProps<typeof motion.ul>,
  'initial' | 'variants' | 'viewport' | 'whileInView'
>;

type RevealItemProps = Omit<ComponentProps<typeof motion.div>, 'variants'>;
type RevealListItemProps = Omit<ComponentProps<typeof motion.li>, 'variants'>;

function useRevealAnimation() {
  const [isMounted, setIsMounted] = useState(false);
  const shouldReduceMotion = useReducedMotion();

  useEffect(() => {
    setIsMounted(true);
  }, []);

  return isMounted && !shouldReduceMotion;
}

function Reveal(props: RevealProps) {
  const shouldAnimate = useRevealAnimation();

  return (
    <motion.div
      data-reveal=""
      {...props}
      initial={shouldAnimate ? 'hidden' : false}
      variants={shouldAnimate ? REVEAL_VARIANTS : undefined}
      viewport={VIEWPORT}
      whileInView={shouldAnimate ? 'visible' : undefined}
    />
  );
}

function RevealGroup(props: RevealGroupProps) {
  const shouldAnimate = useRevealAnimation();

  return (
    <motion.div
      data-reveal-group=""
      {...props}
      initial={shouldAnimate ? 'hidden' : false}
      variants={shouldAnimate ? STAGGER_VARIANTS : undefined}
      viewport={VIEWPORT}
      whileInView={shouldAnimate ? 'visible' : undefined}
    />
  );
}

function RevealList(props: RevealListProps) {
  const shouldAnimate = useRevealAnimation();

  return (
    <motion.ul
      data-reveal-group=""
      {...props}
      initial={shouldAnimate ? 'hidden' : false}
      variants={shouldAnimate ? STAGGER_VARIANTS : undefined}
      viewport={VIEWPORT}
      whileInView={shouldAnimate ? 'visible' : undefined}
    />
  );
}

function RevealItem(props: RevealItemProps) {
  const shouldAnimate = useRevealAnimation();

  return (
    <motion.div
      data-reveal-item=""
      {...props}
      variants={shouldAnimate ? STAGGER_ITEM_VARIANTS : undefined}
    />
  );
}

function RevealListItem(props: RevealListItemProps) {
  const shouldAnimate = useRevealAnimation();

  return (
    <motion.li
      data-reveal-item=""
      {...props}
      variants={shouldAnimate ? STAGGER_ITEM_VARIANTS : undefined}
    />
  );
}

export { Reveal, RevealGroup, RevealItem, RevealList, RevealListItem };
