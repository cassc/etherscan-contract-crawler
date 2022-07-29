//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IGiftContract {
    event UpdateGiftLimit(
        address indexed operator,
        uint8 tierIndex,
        uint256 limit
    );
    event UpdateGiftReserves(address operator, uint16[] reserves);

    event Gift(address indexed, uint8, uint256);
    event GiftEx(address indexed, uint256[]);
    event GiftToAll(address[] indexed, uint256[]);
	
    event Submit(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint8 tierIndex,
        uint256 tokenId,
        bytes data
    );
	//Approval
    event SubmitAndConfirm(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint8 tierIndex,
        uint256 tokenId,
        bytes data
    );
    event Confirm(address indexed owner, uint256 indexed txIndex);
    event ConfirmAndExecute(address indexed owner, uint256 indexed txIndex);

    event Revoke(address indexed owner, uint256 indexed txIndex);
    event Execute(address indexed owner, uint256 indexed txIndex);

    function totalSupply(uint8 tierIndex) external view returns (uint256);

    function isTokenSubmitted(uint8 tierIndex, uint256 tokenId) external view returns (bool);

    function getGiftedList(uint8 tierIndex) external view returns (uint256[] memory);

    function getTransactionCount() external view returns (uint256);

    function getTransaction(uint256 _txIndex)
        external
        view
        returns (
            address to,
            uint8 tierIndex,
            uint256 tokenId,
            bytes memory data,
            bool executed,
            bool reverted,
            uint256 numConfirmations
        );

    function getActiveTxnCount(uint8 _tierIndex) external view returns (uint256);
    function getActiveTokenIds(uint8 _tierIndex) external view returns (uint256[] memory);

    function balanceOf(address user, uint8 tierIndex)
        external
        view
        returns (uint256);
}