// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.4;

pragma experimental ABIEncoderV2;


import "./ISpynNFT.sol";

interface ISpynNFTFactory {


    function getGego(uint256 tokenId)
        external view
        returns (
            uint256 grade,
            uint256 quality,
            uint256 amount,
            uint256 realAmount,
            uint256 resBaseId,
            uint256 ruleId,
            uint256 nftType,
            address author,
            address erc20,
            uint256 createdTime,
            uint256 blockNum,
            uint256 lockedDays
        );


    function getGegoStruct(uint256 tokenId)
        external view
        returns (ISpynNFT.Gego memory gego);

    function burn(uint256 tokenId) external returns ( bool );

    function reflectFee(uint256 tokenId) external;

    function takeFee(uint256 tokenId, uint256 feeAmount, address receipt, bool reflectAmount) external returns (address);

    function isRulerProxyContract(address proxy) external view returns ( bool );
}