s.boot;

a = NetAddr.new("127.0.0.1", 7771);
//specify loop here
b = Buffer.read(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav");
//buffer containing modified loop
c = Buffer.alloc(s, (b.numFrames / b.numChannels), 1);

//play the synth def immediately to fill the buffer (better way to do this?)
(
SynthDef(\record, { arg out = 0, bufnum = 0, sampleBufnum;
    var sig, playbuf;
    sig = PlayBuf.ar(1, sampleBufnum, BufRateScale.kr(sampleBufnum), doneAction:2);
    RecordBuf.ar(sig, bufnum, doneAction: 2, loop: 0);
}).play(s,[\out, 0, \bufnum, c, \sampleBufnum, b]);
)

//TODO: may want to re-arrange this so envelope is applied on playback not on next playback
(
SynthDef(\playback, { arg out = 0, bufnum = 0, cutLevel = 1, cutStart = 0, cutLength = 0;
    var playbuf, recordBuf;
	playbuf = PlayBuf.ar(1,bufnum, doneAction: 2);
	recordBuf = playbuf * EnvGen.kr(Env.step([1, cutLevel, 1], [cutStart, cutLength, 0]));
	RecordBuf.ar(recordBuf, bufnum, doneAction: 2, loop: 0);
		SendReply.kr(Impulse.kr(2), '/amp', Amplitude.kr(playbuf), 1905);
	Out.ar(out,
		GVerb.ar(
        playbuf,
        80,
        4.85,
        0.41,
        0.19,
        15,
        -3.dbamp,
        -9.dbamp,
        -11.dbamp,
        80, 0.3) + playbuf);
}).add;
)

(
var loopLengthInSeconds = ((b.numFrames / b.numChannels) / b.sampleRate);
var taskRepetitions = inf;
var cutLevel = 1;
var cutStart = 0;
var cutLength = 0;
//tweak these values to effectively control the length of the piece
var coinValue = 0.4;
var degradeModifier = 0.01;
var maxPossibleCutLength = 1/6;
var cutStartMap, cutLengthMap;

//set this for a repeatable performance
thisThread.randSeed = 1923;
a.sendMsg("/speed", loopLengthInSeconds);

t = Task({
	taskRepetitions.do({ arg i;
		cutLevel = 1;
		cutStart = 0;
		cutLength = 0;
		if (coinValue.coin, {
		 	cutLevel = 0;
		 	cutStart = loopLengthInSeconds.rand;
			cutLength = (loopLengthInSeconds*maxPossibleCutLength).linrand;
		});
		Synth(\playback, [\out, 0, \bufnum, c, \cutLevel, cutLevel, \cutStart, cutStart, \cutLength, cutLength]);
		coinValue = coinValue + degradeModifier;
		loopLengthInSeconds.wait;
		if (cutLength > 0, {
			cutStartMap = cutStart.linlin(0, loopLengthInSeconds, 0, 1);
			cutLengthMap = cutLength.linlin(0, loopLengthInSeconds, 0, 1);
			a.sendMsg("/cut", cutStartMap.asStringPrec(10) + "," + cutLengthMap.asStringPrec(10));
		});
	});
});
t.start;
//send OSC messages to Processing
OSCFunc({ |msg| a.sendMsg("/amp", msg[3]); }, '/amp');
)

t.stop;