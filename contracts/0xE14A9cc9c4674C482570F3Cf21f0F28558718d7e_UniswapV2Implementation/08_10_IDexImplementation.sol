// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma experimental "ABIEncoderV2";

import {IDomaniDexGeneral} from "../../interfaces/IDomaniDexGeneral.sol";

interface IDexImplementation {
  function swapExactInput(bytes calldata _info, IDomaniDexGeneral.SwapParams memory _inputParams)
    external
    payable
    returns (IDomaniDexGeneral.ReturnValues memory returnValues);

  function swapExactOutput(bytes calldata i_nfo, IDomaniDexGeneral.SwapParams memory _inputParams)
    external
    payable
    returns (IDomaniDexGeneral.ReturnValues memory returnValues);
}