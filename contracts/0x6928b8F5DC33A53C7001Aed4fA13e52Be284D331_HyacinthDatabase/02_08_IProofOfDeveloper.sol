pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IProofOfDeveloper is IERC721 {
    function mint(address developer_) external returns (uint256 id_, address developerWallet_);
    function idHeld(address developer_) external view returns (uint256 id_);
}