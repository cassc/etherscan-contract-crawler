//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@     @@@@@@@@           @@@@@@@@@@@@@@@   @@@@@@@@@@              @@@@//
//@@@@@@             @@@@               @@@@@@@@@@     @@@@@@@@@              @@@@//
//@@@@      @@@@@     @@@    @@@@@@@     @@@@@@@@       @@@@@@@@@@@@@@@@@     @@@@//
//@@@@     @@@@@@@@@@@@@@    @@@@@@@     @@@@@@@@        @@@@@@@@@@@@@@     @@@@@@//
//@@@@     @@@@        @@               @@@@@@@     @@    @@@@@@@@@@@     @@@@@@@@//
//@@@@     @@@@        @@            @@@@@@@@@     @@@@    @@@@@@@@#     @@@@@@@@@//
//@@@@     @@@@@@@     @@    @@@@     @@@@@@@               @@@@@@     @@@@@@@@@@@//
//@@@@@               @@@    @@@@@@     @@@@                 @@@               @@@//
//@@@@@@@           @@@@@    @@@@@@@     @@     @@@@@@@@@@    @@               @@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//

import { Owned } from "solmate/auth/Owned.sol";
import { ERC1155 } from "solmate/tokens/ERC1155.sol";
import { IGRAZ, Edition } from "./interfaces/IGRAZ.sol";

contract GRAZ is Owned, ERC1155, IGRAZ {
    /*//////////////////////////////////////////////////////////////
                                 Errors
    //////////////////////////////////////////////////////////////*/

    error InvalidOwnerAddress();
    error InvalidWithdrawReceiverAddress();
    error InvalidFactoryAddress();
    error SupplyLimit();
    error MintNotStarted();
    error PayTheFee();
    error ReachedLimit();
    error InvalidMintQuantity();
    error CallerIsNotEOA();
    error CallerIsNotOwnerOrFactory();

    /*//////////////////////////////////////////////////////////////
                                 State vars
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Flag which determines if minting is allowed or not
     */
    bool public mintStarted;

    /**
     * @notice Address of a factory contract
     * @dev external contract to be used in the future for other interactions
     */
    address public grazFactory;

    /**
     * @notice The name of the contract
     */
    string public name;

    /**
     * @notice The symbol of the contract
     */
    string public symbol;

    /**
     * @notice Mapping containing the minted tokens for each edition
     */
    mapping(uint256 => uint256) public editionSupply;

    /**
     * @notice Array containing all editions
     */
    Edition[] public editions;

    /*//////////////////////////////////////////////////////////////
                                 Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyEOA() {
        if (tx.origin != msg.sender) revert CallerIsNotEOA();
        _;
    }

    modifier onlyOwnerOrFactory() {
        if (msg.sender != grazFactory && msg.sender != owner) revert CallerIsNotOwnerOrFactory();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, address owner) Owned(owner) {
        if (owner == address(0)) revert InvalidOwnerAddress();
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                                 Functions start
    //////////////////////////////////////////////////////////////*/

    /// MINTING FUNCTIONS

    function ownerMint(address reciever, uint256 tokenId, uint256 quantity) external onlyOwner {
        if (quantity == 0) revert InvalidMintQuantity();
        Edition storage edition = editions[tokenId];
        if (editionSupply[tokenId] + quantity > edition.maxSupply) {
            revert SupplyLimit();
        }
        editionSupply[tokenId] += quantity;
        _mint(reciever, tokenId, quantity, "");
    }

    function mintToken(uint256 tokenId, uint256 quantity) external payable onlyEOA {
        if (quantity == 0) revert InvalidMintQuantity();

        if (mintStarted == false) {
            revert MintNotStarted();
        }

        Edition storage edition = editions[tokenId];

        if (msg.value < (quantity * edition.editionPrice)) {
            revert PayTheFee();
        }
        if (balanceOf[msg.sender][tokenId] + quantity > edition.mintCap) {
            revert ReachedLimit();
        }

        if (editionSupply[tokenId] + quantity > edition.maxSupply) {
            revert SupplyLimit();
        }

        editionSupply[tokenId] += quantity;
        _mint(msg.sender, tokenId, quantity, "");
    }

    /// BURNING FUNCTIONS

    function burnToken(address from, uint256 id, uint256 amount) external onlyOwnerOrFactory {
        _burn(from, id, amount);
    }

    function batchBurnTokens(address from, uint256[] memory ids, uint256[] memory amounts) external onlyOwnerOrFactory {
        _batchBurn(from, ids, amounts);
    }

    /// MANAGEMENT FUNCTIONS

    function toggleMint() external onlyOwner {
        mintStarted = !mintStarted;
    }

    function setFactoryAddress(address factory) external onlyOwner {
        if (factory.code.length == 0) revert InvalidFactoryAddress();
        grazFactory = factory;
    }

    function createEdition(uint256 _supply, uint256 _price, string memory _uri, uint256 _mintCap) external onlyOwner {
        editions.push(Edition(_supply, _price, _uri, _mintCap));
    }

    function editEdition(uint256 _tokenId, uint256 _supply, uint256 _price, string memory _uri, uint256 _mintCap) external onlyOwner {
        Edition storage edition = editions[_tokenId];
        edition.maxSupply = _supply;
        edition.editionPrice = _price;
        edition.editionURI = _uri;
        edition.mintCap = _mintCap;
    }

    function withdrawFunds(address receiver) external onlyOwner {
        if (receiver == address(0)) revert InvalidWithdrawReceiverAddress();
        uint256 balance = address(this).balance;
        payable(receiver).transfer(balance);
    }

    /// VIEW FUNCTIONS

    function uri(uint256 tokenId) public view override returns (string memory) {
        Edition storage edition = editions[tokenId];
        return edition.editionURI;
    }
}