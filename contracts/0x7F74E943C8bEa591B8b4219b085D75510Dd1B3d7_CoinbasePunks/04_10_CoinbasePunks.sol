// SPDX-License-Identifier: MIT
//
//  _____     _     _                              _
// |     |___|_|___| |_ ___ ___ ___    ___ _ _ ___| |_ ___
// |   --| . | |   | . | .'|_ -| -_|  | . | | |   | '_|_ -|
// |_____|___|_|_|_|___|__,|___|___|  |  _|___|_|_|_,_|___|
//                                    |_|
//
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "solady/utils/LibString.sol";
import "solady/utils/SafeTransferLib.sol";
import "./layerzero/Ownable.sol";
import "./layerzero/NonblockingLzApp.sol";

contract CoinbasePunks is ERC721, Ownable, NonblockingLzApp {
    using LibString for uint256;

    /*//////////////////////////////////////////////////////////////
                             CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    error NoContracts();
    error TooManyMints();
    error IncorrectFunds();
    error NotEnoughSupply();
    error MintNotActive();
    error NotTokenOwner();

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_AMOUNT = 5;

    uint256 public price;
    uint256 public totalSupply;
    bool public mintActive;
    string public baseURI;

    // constructor requires the LayerZero endpoint for this chain
    constructor(address _endpoint)
        ERC721("Coinbase Punks", "CBP")
        NonblockingLzApp(_endpoint)
    {
        // mint 100 for the team + giveaways
        _mintPunks(100);
    }

    /*//////////////////////////////////////////////////////////////
                                  PUBLIC
    //////////////////////////////////////////////////////////////*/

    function mint(uint256 amount) external payable {
        if (!mintActive) revert MintNotActive();
        if (tx.origin != msg.sender) revert NoContracts();
        if (amount > MAX_AMOUNT) revert TooManyMints();
        if (msg.value != price * amount) revert IncorrectFunds();
        if (amount + totalSupply > MAX_SUPPLY) revert NotEnoughSupply();

        _mintPunks(amount);
    }

    // This function transfers the nft from sender on the
    // source chain to the same address on the destination chain
    function traverseChains(uint16 _chainId, uint256 tokenId) public payable {
        if (msg.sender == ownerOf(tokenId)) revert NotTokenOwner();

        // burn NFT on this chain
        _burn(tokenId);

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350000;

        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );

        _lzSend( // {value: messageFee}
            _chainId, // destination chainId
            payload, // abi.encode()'ed bytes
            payable(msg.sender), // refund address (LayerZero will refund any extra gas back to caller of send()
            address(0x0), // future param, unused for this
            adapterParams, // v1 adapterParams, specify custom destination gas qty
            msg.value
        );
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _mintPunks(uint256 amount) internal {
        uint256 currSupply = totalSupply;

        unchecked {
            uint256 i;
            for (; i < amount; ) {
                _mint(msg.sender, currSupply++);
                ++i;
            }
        }

        totalSupply = currSupply;
    }

    // callback is called when NFTs traverse chains
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal override {
        // old way:
        // address sendBackToAddress;
        // assembly {
        //     sendBackToAddress := mload(add(_srcAddress, 20))
        // }

        // decode
        (address toAddr, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        // mint the tokens back into existence on this chain
        _mint(toAddr, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                                  VIEW
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/

    function flipMint() external onlyOwner {
        mintActive = !mintActive;
    }

    function setPrice(uint256 mintPrice) external onlyOwner {
        price = mintPrice;
    }

    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }
}