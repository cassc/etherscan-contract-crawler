// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721m.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Rareland is ERC721m, Pausable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 internal constant MAX_SUPPLY = 10000;
    uint256 internal constant MAX_MINT_AMOUNT_PER_TX = 1;
    uint256 internal constant MAX_MINT_AMOUNT_PER_ADDRESS = 1;
    
    constructor() ERC721m("Rareland", "RARE") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @param _to The recipient of the new avatar
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * - `to` cannot be the zero address.
     * Emits {Transfer} events.
     */
    function safeMintAvatar(address _to)
        external
        payable
    {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(totalSupply() <= MAX_SUPPLY, "not enough avatars remaining reserved for minting");
        require(balanceOf(msg.sender) == 0, "One address can only mint one!");

        _safeMint(_to, 1);
    }

    /**
     * @param _addresses The addresses that receive the dev minted avatars.
     * Requirements:
     *
     * - If `_addresses` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * - `_addresses` cannot be the zero address.
     * Emits _amount number of {Transfer} events.
     */
    function devMintToAddresses(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _safeMint(_addresses[i], 1);
        }
    }

    /**
     * @dev Withdraws all the amount balance from the contract to the `owner` address.
     */
    function withdraw() external onlyOwner nonReentrant {
        // The `owner()` function is a public function from '@openzeppelin/contracts/access/Ownable.sol'
        // The conversion from non payable to payable address must be explicit,
        // see: https://docs.soliditylang.org/en/latest/types.html#address
        address payable owner = payable(owner());

        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        transferFund(owner, amount);
    }

    /**
     * @dev Transfers `amount` wei to the `recipient` address, 
     * forwarding all available gas and reverting on errors.
     * 
     * @param _recipient The recipient of the fund.
     * @param _amount the amount to be transferred.
     *
     * We get rid of the transfer() and value() functions because of the 2300 gas limit,
     * as https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     *
     * For more explanation, please refer to:
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/.
     */
    function transferFund(address payable _recipient, uint256 _amount) internal {
        (bool success, ) = _recipient.call{ value: _amount }("");
        require(success, "Failed to send Ether to the recipient!");
    }

    /**
     * @dev  Gets back a list of NFTs owned by the address.
     */
    function getNftsByOwner(address _owner) external view returns(uint256[] memory) {
       uint256 count = balanceOf(_owner);

       /// In Solidity it is not possible to create dynamic arrays in memory,
       /// memory arrays must be created with a length argument.
       uint256[] memory result = new uint256[](count);
       
       uint256 currentTokenId = 0;
       uint256 ownedTokenIndex = 0;
       while (ownedTokenIndex < count && currentTokenId < MAX_SUPPLY) {
           if (ownerOf(currentTokenId) == _owner) {
               result[ownedTokenIndex] = currentTokenId;
               ++ownedTokenIndex;
           }
           ++currentTokenId;
       }

       return result;
    }

    // Metadata URI implementation

    string private _baseTokenUri;

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenUri;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        _baseTokenUri = _baseUri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
        bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString()))
            : "";
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }
}