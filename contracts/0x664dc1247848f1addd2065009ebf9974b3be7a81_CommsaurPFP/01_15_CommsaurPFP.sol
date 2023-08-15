// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//   .--.      .--.    ___ .-. .-.    ___ .-. .-.       .--.      .---.   ___  ___   ___ .-.
//  /    \    /    \  (   )   '   \  (   )   '   \    /  _  \    / .-, \ (   )(   ) (   )   \
// |  .-. ;  |  .-. ;  |  .-.  .-. ;  |  .-.  .-. ;  . .' `. ;  (__) ; |  | |  | |   | ' .-. ;
// |  |(___) | |  | |  | |  | |  | |  | |  | |  | |  | '   | |    .'`  |  | |  | |   |  / (___)
// |  |      | |  | |  | |  | |  | |  | |  | |  | |  _\_`.(___)  / .'| |  | |  | |   | |
// |  | ___  | |  | |  | |  | |  | |  | |  | |  | | (   ). '.   | /  | |  | |  | |   | |
// |  '(   ) | '  | |  | |  | |  | |  | |  | |  | |  | |  `\ |  ; |  ; |  | |  ; '   | |
// '  `-' |  '  `-' /  | |  | |  | |  | |  | |  | |  ; '._,' '  ' `-'  |  ' `-'  /   | |
//  `.__,'    `.__.'  (___)(___)(___)(___)(___)(___)  '.___.'   `.__.'_.   '.__.'   (___)
// @author erosemberg

contract CommsaurPFP is
    ERC721Enumerable,
    IERC721Receiver,
    ReentrancyGuard,
    Ownable
{
    IERC721 public immutable commsaurContract;

    string private baseURI;

    struct WrappingState {
        bool wrappingEnabled;
        bool unwrappingEnabled;
    }

    WrappingState public wrappingState;

    constructor(address _commsaurAddress) ERC721("Wrapped Commsaur", "WCOMMSAUR") {
        commsaurContract = IERC721(_commsaurAddress);
        wrappingState = WrappingState({
            wrappingEnabled: false,
            unwrappingEnabled: false
        });
    }

    function setWrappingEnabled(bool _enabled) external onlyOwner {
        wrappingState.wrappingEnabled = _enabled;
    }

    function setUnwrappingEnabled(bool _enabled) external onlyOwner {
        wrappingState.unwrappingEnabled = _enabled;
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual override nonReentrant returns (bytes4) {
        if (msg.sender == address(commsaurContract)) {
            // solhint-disable-next-line reason-string
            require(
                wrappingState.wrappingEnabled,
                "Commsaur: Wrapping is not currently enabled!"
            );
            if (!_exists(tokenId)) {
                _safeMint(from, tokenId);
            } else {
                // @note this will require token approval
                _safeTransfer(address(this), from, tokenId, "");
            }
        } else if (msg.sender == address(this)) {
            // solhint-disable-next-line reason-string
            require(
                wrappingState.unwrappingEnabled,
                "Commsaur: Unwrapping is not currently enabled!"
            );
            commsaurContract.safeTransferFrom(address(this), from, tokenId);
        } else {
            // solhint-disable-next-line reason-string
            revert("Commsaur: Only Commsaurs are allowed into this dinoverse!");
        }

        return this.onERC721Received.selector;
    }

    function wrapHerd(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            commsaurContract.safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }
    }

    function unwrapHerd(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    function rescue(address to, uint256 tokenId) external onlyOwner {
        if (!_exists(tokenId) || ownerOf(tokenId) == address(this)) {
            commsaurContract.safeTransferFrom(address(this), to, tokenId);
        } else if (ownerOf(tokenId) == address(commsaurContract)) {
            _safeTransfer(address(commsaurContract), to, tokenId, "");
        } else {
            // solhint-disable-next-line reason-string
            revert("Commsaur: That Commsaur seems to be in the right place?");
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }
}