// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC721Mintable is IERC721, IERC2981 {
    function mintingCharge() external view returns (uint256);

    function royalities(uint256 _tokenId) external view returns (uint256);

    function creators(uint256 _tokenId) external view returns (address payable);

    function broker() external view returns (address payable);

    function ecosystemContract(address) external view returns (bool);

    struct _brokerage {
        uint256 seller;
        uint256 buyer;
    }

    function brokerage() external view returns (_brokerage calldata);

    function delegatedMint(
        string memory tokenURI,
        uint96 _royalty,
        address _to,
        address _receiver
    ) external returns (uint);
}