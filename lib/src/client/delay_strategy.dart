typedef DelayStrategy = Duration Function({
  required Duration current,
  required Duration initial,
});

class DelayStrategies {
  /// A delay strategy that grows linearly by adding the initial delay to the
  /// current.
  static final linear = ({
    required Duration current,
    required Duration initial,
  }) =>
      initial + current;

  /// A delay strategy that grows exponentially by always adding the current
  /// delay to itself.
  static final progressive = ({
    required Duration current,
    required Duration initial,
  }) =>
      current + current;
}
