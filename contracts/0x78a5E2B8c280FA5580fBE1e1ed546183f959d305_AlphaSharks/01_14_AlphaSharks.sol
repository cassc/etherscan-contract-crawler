// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/*

░█████╗░██╗░░░░░██████╗░██╗░░██╗░█████╗░  ░██████╗██╗░░██╗░█████╗░██████╗░██╗░░██╗░██████╗
██╔══██╗██║░░░░░██╔══██╗██║░░██║██╔══██╗  ██╔════╝██║░░██║██╔══██╗██╔══██╗██║░██╔╝██╔════╝
███████║██║░░░░░██████╔╝███████║███████║  ╚█████╗░███████║███████║██████╔╝█████═╝░╚█████╗░
██╔══██║██║░░░░░██╔═══╝░██╔══██║██╔══██║  ░╚═══██╗██╔══██║██╔══██║██╔══██╗██╔═██╗░░╚═══██╗
██║░░██║███████╗██║░░░░░██║░░██║██║░░██║  ██████╔╝██║░░██║██║░░██║██║░░██║██║░╚██╗██████╔╝
╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝  ╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░
*/

contract AlphaSharks is AccessControl, ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    /** ADDRESSES */
    address public stakingContract;
    address public breedingContract;
    address public sharkToken;

    /** ROLES */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    /** EVENTS */
    event SetStakingContract(address _stakingContract);
    event SetBreedingContract(address _breedingContract);
    event SetSharkTokens(address _sharkToken);

    function setStakingContract(address _stakingContract)
        external
        onlyRole(DAO_ROLE)
    {
        stakingContract = _stakingContract;
        emit SetStakingContract(_stakingContract);
    }

    function setBreedingContract(address _breedingContract)
        external
        onlyRole(DAO_ROLE)
    {
        breedingContract = _breedingContract;
        emit SetBreedingContract(_breedingContract);
    }

    function setSharkTokensContract(address _sharkToken)
        external
        onlyRole(DAO_ROLE)
    {
        sharkToken = _sharkToken;
        emit SetSharkTokens(_sharkToken);
    }

    uint256 public MAXIMUM_SUPPLY = 6969;
    string public BASE_URI = "ipfs://abcd/";

    constructor() ERC721A("AlphaSharks", "ALPHASHARKS") {
        // Owner is an admin
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function updateBaseURI(string memory _BASE_URI) external onlyOwner {
        BASE_URI = _BASE_URI;
    }

    function safeMint(address _to, uint256 quantity)
        external
        onlyRole(MINTER_ROLE)
    {
        require(
            totalSupply() + quantity <= MAXIMUM_SUPPLY,
            "Max supply reached"
        );
        _safeMint(_to, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No ether to withdraw");
        payable(owner()).transfer(address(this).balance);
    }
}