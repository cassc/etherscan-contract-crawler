// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";

contract NFTCollection is ERC721A, Owned {
    string public constant BASE_EXTENSION = ".json";

    uint256 public immutable maxMintAmount;

    uint256 public cost;
    uint256 public maxSupply;
    string public baseURI;
    bool public revealed = false;

    error MinimumOneNFT();
    error MaxSupplyExceeded();
    error InsufficientValue();
    error MaxMintAmountExceeded();
    error NonExistentToken();
    error FailedToSendFundsToOwner();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _notRevealedUri,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmount,
        address _owner
    ) ERC721A(_name, _symbol) Owned(_owner) {
        baseURI = _notRevealedUri;
        cost = _cost;
        maxSupply = _maxSupply;
        maxMintAmount = _maxMintAmount;
    }

    // internal
    function _mintAmount(uint256 _amount) internal virtual {
        if (_amount == 0) {
            revert MinimumOneNFT();
        }
        if (_amount > maxMintAmount) {
            revert MaxMintAmountExceeded();
        }
        if (_totalMinted() + _amount > maxSupply) {
            revert MaxSupplyExceeded();
        }
        _safeMint(msg.sender, _amount);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // public
    function mint(uint256 _amount) public payable virtual {
        if (msg.value < cost * _amount) {
            revert InsufficientValue();
        }
        _mintAmount(_amount);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) {
            revert NonExistentToken();
        }
        if (revealed) {
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            baseURI,
                            _toString(_tokenId),
                            BASE_EXTENSION
                        )
                    )
                    : "";
        }
        return baseURI;
    }

    // only ownner
    function reveal() external onlyOwner {
        revealed = true;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(owner).call{value: address(this).balance}("");
        if (!sent) {
            revert FailedToSendFundsToOwner();
        }
    }
}