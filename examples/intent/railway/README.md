# Railway intent example

This example is a structural reference for Idriç: say what is being drawn first,
then descend into geometry and finally into pen/PostScript mechanics only when a
reader needs them.

The notation here is intent-oriented. It is not a claim that every phrase is
already accepted by the current parser.

## Top level: the thing the user asked for

```idric
page ≝ postscript_page
output ≝ "railway.ps"

draw railway_track on page
save page to output
```

A reader should not have to understand line caps, coordinate arithmetic, or
PostScript operators to discover that this program draws a railway track.

## One level down: railway geometry

```idric
draw railway_track on page ≝
    draw left_rail on page
    draw right_rail on page
    draw sleepers on page between left_rail and right_rail
```

`left_rail`, `right_rail`, and `sleepers` are domain objects. Their geometry can
be inspected separately without replacing the top-level purpose with a pile of
line operations.

## Deeper: one rail as a visible line

```idric
draw rail on page from start to finish ≝
    set line_width on page to rail_width
    move pen on page to start
    draw line on page to finish
    stroke path on page
```

A concrete PostScript implementation may go deeper again and map those actions
to `setlinewidth`, `moveto`, `lineto`, and `stroke`. That machinery belongs below
the railway vocabulary, not in place of it.

## What this example establishes

- top-level source names the intended object before its mechanism;
- grammatical role words such as `on`, `from`, `to`, and `between` make argument
  roles visible;
- a higher-level action can have several progressively more concrete
  implementations;
- folder/file depth can mirror that descent without forcing the semantic phrase
  to match one particular filesystem ownership convention;
- a visible result such as `railway.ps` gives the example a concrete acceptance
  target.
