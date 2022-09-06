// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IMintGateway {
  function mint(
    bytes32 _pHash,
    uint256 _amount,
    bytes32 _nHash,
    bytes calldata _sig
  ) external returns (uint256);

  function mintFee() external view returns (uint256);
}

interface IBurnGateway {
  function burn(bytes memory _to, uint256 _amountScaled) external returns (uint256);

  function burnFee() external view returns (uint256);
}

interface IGateway is IMintGateway, IBurnGateway {

}

/*
interface IGateway is IMintGateway, IBurnGateway {
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function mintFee() external view returns (uint256);

    function burn(bytes calldata _to, uint256 _amountScaled)
        external
        returns (uint256);

    function burnFee() external view returns (uint256);
}
*/