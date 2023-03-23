// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ILayerrVariables {

  /* 
  * @dev returns the address of the layerr payout wallet
  */
  function viewWithdraw() view external returns(address);

  /**
  * @dev returns the address of the layerr signer wallet
  */
  function viewSigner() view external returns(address);

  /**
  * @dev returns the percentage fee paid by creators to layerr
  *     if a specific fee is set for the creator, that is returned
  *     otherwise the default fee is returned
  *     50 = 5%
  *     25 = 2.5%
  */
  function viewFee(address _address) view external returns(uint);

  /* @dev returns the flat fee paid by minters to layerr
  *     if a specific fee is set for the creator, that is returned
  *     otherwise the default fee is returned
  */
  function viewFlatFee(address _address) view external returns(uint);
}