/// The three actions on a blind card (06 §4).
///
/// Right = [long], left = [short] via swipe; [cash] via the Cash button
/// (the vertical axis is reserved for scrolling the card). All three are on the
/// Short / Cash / Long button row.
enum Choice { long, short, cash }
