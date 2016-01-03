equalById = (array1, array2) ->
  if array1 instanceof Array and array2 instanceof Array
    array1.length == array2.length and
      [0...array1.length].every (i) -> equalById(array1[i], array2[i])
  else
    array1 and array2 and array1?.id == array2?.id

ids = (thing) ->
  if thing instanceof Array
    ids(x) for x in thing
  else
    thing.id

matchers =
  # Comparing models makes things super slow in the failure case. Compare them
  # by ids instead.
  toEqualById: (expected) ->
    expectedIds = ids(expected)
    actualIds = ids(@actual)
    @message = -> "Expected [#{actualIds.toString()}] to match [#{expectedIds.toString()}]"
    equalById(@actual, expected)

module.exports =
  matchers: matchers
