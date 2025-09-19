import { BooleanLike } from '../../common/react';
import { useBackend } from '../backend';
import { Box, Button, LabeledList, NumberInput, Section, ProgressBar } from '../components';
import { InterfaceLockNoticeBox } from './common/InterfaceLockNoticeBox';
import { classes } from '../../common/react';
import { Window } from '../layouts';

export type StatusData = {
  state: string;
  lock: string;
};

export type AACData = {
  locked: BooleanLike;
  siliconUser: BooleanLike;
  chamber_pressure: number;
	external_pressure: number;
	internal_pressure: number;
	processing: BooleanLike;
	purge: BooleanLike;
	secure: BooleanLike;
  interior_status: StatusData;
  exterior_status: StatusData;
};

export const AdvancedAirlockConsole = (props, context) => {
  const { state } = props;
  const { act, data } = useBackend<AACData>(context);
  const locked = data.locked && !data.siliconUser;
  return (
    <Window resizeable theme="hephaestus">
      <Window.Content>
        <InterfaceLockNoticeBox
          siliconUser={data.siliconUser}
          locked={data.locked}
          onLockStatusChange={() => act('lock')} />
        <AACStatus state={state} />
        <AACControl state={state} />
        {!locked && (
          <AACMaint state={state} />
        )}
      </Window.Content>
    </Window>
  );
};

export const AACStatus = (props, context) => {
  const { state } = props;
  const { act, data } = useBackend<AACData>(context);
  return (
    <Window resizable>
      <Window.Content scrollable>
        <Section title="Status">
          <Box>
            <LabeledList>
              <LabeledList.Item label="Airlock Status">
                <Box>{{}}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Chamber Pressure">
                <ProgressBar
                  ranges={{
                    average: [120, Infinity],
                    good: [80, 120],
                    bad: [-Infinity, 80],
                  }}
                  value={data.chamber_pressure}
                  minValue={0}
                  maxValue={200}>
                  {data.chamber_pressure} kPa
                </ProgressBar>
              </LabeledList.Item>
            </LabeledList>
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};

export const AACControl = (props, context) => {
  const { state } = props;
  const { act, data } = useBackend<AACData>(context);
  return (
        <Section title="Controls">
          <Box>
            <Button
              content="Cycle to Exterior"
              icon="arrow-right-from-bracket"
              onClick={() => act('command', { command: 'cycle_ext' })}
            />
            <Button
              content="Cycle to Interior"
              icon="arrow-right-to-bracket"
              onClick={() => act('command', { command: 'cycle_int' })}
            />
          </Box>
          <Box>
            <Button
              content="Force Exterior Door"
              icon="circle-exclamation"
              color={data.interior_status.state === 'open'
                    ? 'red'
                    : 'yellow'
              }
              onClick={() => act('command', { command: 'force_ext' })}
            />
            <Button
              content="Force Interior Door"
              icon="circle-exclamation"
              color={data.exterior_status.state === 'open'
                    ? 'red'
                    : 'yellow'
              }
              onClick={() => act('command', { command: 'force_int' })}
            />
          </Box>
          <Box>
            <Button
              content="Abort"
              icon="ban"
              disabled={!data.processing}
              color={!data.processing ? null : 'red'}
              onClick={() => act('command', { command: 'abort' })}
            />
          </Box>
        </Section>
  );
};

export const AACMaint = (props, context) => {

};
