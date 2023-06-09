//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./utils/IERC721.sol";

/** @title palLoanToken Interface  */
/// @author Paladin
interface IPalLoanToken is IERC721 {

    //Events

    /** @notice Event when a new Loan Token is minted */
    event NewLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);
    /** @notice Event when a Loan Token is burned */
    event BurnLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);


    //Functions
    function mint(address to, address palPool, address palLoan) external returns(uint256);
    function burn(uint256 tokenId) external returns(bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokenOfByIndex(address owner, uint256 tokenIdex) external view returns (uint256);
    function loanOf(uint256 tokenId) external view returns(address);
    function poolOf(uint256 tokenId) external view returns(address);
    function loansOf(address owner) external view returns(address[] memory);
    function tokensOf(address owner) external view returns(uint256[] memory);
    function loansOfForPool(address owner, address palPool) external view returns(address[] memory);
    function allTokensOf(address owner) external view returns(uint256[] memory);
    function allLoansOf(address owner) external view returns(address[] memory);
    function allLoansOfForPool(address owner, address palPool) external view returns(address[] memory);
    function allOwnerOf(uint256 tokenId) external view returns(address);

    function isBurned(uint256 tokenId) external view returns(bool);

    //Admin functions
    function setNewController(address _newController) external;
    function setNewBaseURI(string memory _newBaseURI) external;

}