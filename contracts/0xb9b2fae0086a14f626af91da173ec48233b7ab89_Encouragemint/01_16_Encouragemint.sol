//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./render/Utils.sol";
import "./render/IRenderer.sol";

contract Encouragemint is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_BATCH_SIZE = 6;

    bool public isMintActive = false;
    IRenderer public renderer;

    constructor(address _rendererAddress) ERC721A("Encouragemint", "WORDS") {
        renderer = IRenderer(_rendererAddress); 
    }

    /**
     * @notice Mint a quantity of tokens to a given address when minting is active
     * @param _quantity Number of tokens to mint
     * @param _to Address to mint tokens to
     */
    function mint(uint256 _quantity, address _to) external payable nonReentrant {
        require(isMintActive, "Minting inactive");
        require(_quantity <= MAX_BATCH_SIZE, "Quantity exceeds max");
        require(msg.value == 0 ether, "No payment required");
        require(_to != address(0), "Mint to zero address");

        _safeMint(_to, _quantity);
    }

    /**
     * @notice Generate on-chain token URI
     * @param _tokenId Token id
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Nonexistant token");

    //   return renderer.render(_tokenId);
        return string.concat(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"Words of Encouragemint #',
                        utils.uint2str(_tokenId),
                        '","description":"On-chain positivity, brought to you by Cameo Pass.","image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(renderer.render(_tokenId, ownerOf(_tokenId)))),
                        '"}'
                    )
                )
            )
        );
    }

    /**
     * @notice Set whether minting is active
     * @notice Use restricted to contract owner
     * @param _isMintActive New `isMintActive` value
     */
    function setIsMintActive(bool _isMintActive) external onlyOwner {
        isMintActive = _isMintActive;
    }

    /**
     * @notice Set renderer contract
     * @notice Use restricted to contract owner
     * @param _rendererAddress new renderer contract address
     */
    function setRenderer(address _rendererAddress) external onlyOwner {
        renderer = IRenderer(_rendererAddress);
    }

    /**
     * @notice Withdraw all funds to the contract owners address
     * @notice Use restricted to contract owner
     * @dev `transfer` and `send` assume constant gas prices. This function
     * is onlyOwner, so we accept the reentrancy risk that `.call.value` carries.
     */
    function withdraw() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    fallback() external payable {
        require(false, "Not implemented");
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    receive() external payable {
        require(false, "Not implemented");
    }
}