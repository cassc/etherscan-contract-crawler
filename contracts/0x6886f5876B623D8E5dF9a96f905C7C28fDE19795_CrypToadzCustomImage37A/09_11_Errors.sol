// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

error UnsupportedDrawInstruction(uint8 instructionType);
error DoNotAddBlackToColorTable();
error InvalidDrawOrder(uint8 featureId);
error FailedToDecompress(uint errorCode);
error InvalidDecompressionLength(uint expected, uint actual);
error ImageFileOutOfRange(uint value);
error TraitOutOfRange(uint value);
error BadTraitCount(uint8 value);
error BadTraitChoice(uint8 value);