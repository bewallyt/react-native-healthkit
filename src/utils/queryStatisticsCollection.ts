import ensureUnit from "./ensureUnit";
import Native from "../native-types";

import type {
  HKQuantityTypeIdentifier,
  HKStatisticsOptions,
  UnitForIdentifier,
} from "../native-types";

// Interval is in minutes
async function queryStatisticsCollection<
  TIdentifier extends HKQuantityTypeIdentifier,
  TUnit extends UnitForIdentifier<TIdentifier> = UnitForIdentifier<TIdentifier>
>(
  identifier: TIdentifier,
  options: readonly HKStatisticsOptions[],
  from: Date,
  to: Date | undefined,
  interval: number,
  anchorDate: Date,
  unit?: TUnit
) {
  const actualUnit = await ensureUnit(identifier, unit);
  const toDate = to || new Date();
  const { mostRecentQuantityDateInterval, ...rawResponse } =
    await Native.queryStatisticsCollection(
      identifier,
      actualUnit,
      from.toISOString(),
      toDate.toISOString(),
      interval,
      anchorDate.toISOString(),
      options
    );

  const response = {
    ...rawResponse,
    ...(mostRecentQuantityDateInterval
      ? {
          mostRecentQuantityDateInterval: {
            from: new Date(mostRecentQuantityDateInterval.from),
            to: new Date(mostRecentQuantityDateInterval.to),
          },
        }
      : {}),
  };

  return response;
}

export default queryStatisticsCollection;
