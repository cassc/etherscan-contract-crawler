// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Samos is ERC721A, Ownable, Pausable {
    using ECDSA for bytes32;

    // mint state
    enum State {
        PREPARE,
        WHITE_LIST_MINT,
        PUBLIC_MINT,
        FINISHED
    }

    State public mintState;

    uint256 public COLLECTION_SIZE = 10010;

    uint256 public WHITE_LIST_MINT_COST = 0.03 ether;

    uint256 public MINT_COST = 0.05 ether;

    address public walletAddress;

    address public signerAddress;

    uint256 private minBatchSize = 5;

    string private baseTokenURI;

    bool private _bypassSignatureChecking = false;

    modifier onlyEOA() {
        if (msg.sender != tx.origin) {
            revert();
        }
        _;
    }

    event SignerAddressUpdated(
        address indexed oldSignerAddress,
        address indexed newSignerAddress
    );

    constructor(
        address _walletAddress,
        address _signerAddress,
        string memory _baseTokenURI
    ) ERC721A("Samos", "SAMOS") {
        mintState = State.PREPARE;
        walletAddress = _walletAddress;
        signerAddress = _signerAddress;
        baseTokenURI = _baseTokenURI;
    }

    /** @dev whitelist mint */
    function whitelistMint(
        string memory _nonce,
        uint256 _quantity,
        bytes memory _signature
    ) external payable onlyEOA whenNotPaused {
        require(
            mintState == State.WHITE_LIST_MINT,
            "Whitelist Mint is not available."
        );

        require(
            totalSupply() + _quantity <= COLLECTION_SIZE,
            "Reached max supply."
        );

        require(
            msg.value >= (WHITE_LIST_MINT_COST * _quantity),
            "Not paying enough ETH to mint."
        );

        if (!_bypassSignatureChecking) {
            require(
                isSignedBySigner(
                    msg.sender,
                    _nonce,
                    _quantity,
                    _signature,
                    signerAddress
                ),
                "Incorrect signature."
            );
        }

        // transfer the fund to the project team
        payable(walletAddress).transfer(msg.value);

        _mintNFT(msg.sender, _quantity);
    }

    /** @dev public mint */
    function publicMint(
        uint256 _quantity
    ) external payable onlyEOA whenNotPaused {
        require(mintState == State.PUBLIC_MINT, "Mint is not available.");

        require(
            totalSupply() + _quantity <= COLLECTION_SIZE,
            "Reached max supply."
        );

        require(
            msg.value >= (MINT_COST * _quantity),
            "Not paying enough ETH to mint."
        );

        // transfer the fund to the project team
        payable(walletAddress).transfer(msg.value);

        if (_quantity >= minBatchSize) {
            uint _batchCount = _quantity / minBatchSize;
            uint _reminder = _quantity % minBatchSize;

            for (uint i = 0; i < _batchCount; i++) {
                _mintNFT(msg.sender, minBatchSize);
            }

            if (_reminder > 0) {
                _mintNFT(msg.sender, _reminder);
            }
        } else {
            _mintNFT(msg.sender, _quantity);
        }
    }

    /** @dev mint
     */
    function _mintNFT(address _toAddress, uint256 quantity) internal {
        _safeMint(_toAddress, quantity);
    }

    /** @dev airdrop to user with fixed quantity
     */
    function fixedAirDrop(
        address[] memory _addressList,
        uint256 _quantity
    ) external onlyOwner {
        uint256 sum = _addressList.length * _quantity;

        require(totalSupply() + sum <= COLLECTION_SIZE, "Reached max supply.");

        for (uint256 i = 0; i < _addressList.length; i++) {
            if (_quantity >= minBatchSize) {
                uint _batchCount = _quantity / minBatchSize;
                uint _reminder = _quantity % minBatchSize;

                for (uint256 c = 0; c < _batchCount; c++) {
                    _mintNFT(_addressList[i], minBatchSize);
                }

                if (_reminder > 0) {
                    _mintNFT(_addressList[i], _reminder);
                }
            } else {
                _mintNFT(_addressList[i], _quantity);
            }
        }
    }

    /** @dev airdrop to user with dynamic quantity
     */
    function dynamicAirDrop(
        address[] memory _addressList,
        uint256[] memory _quantityList
    ) external onlyOwner {
        uint256 sum;

        for (uint256 i = 0; i < _quantityList.length; i++) {
            sum += _quantityList[i];
        }

        require(totalSupply() + sum <= COLLECTION_SIZE, "Reached max supply.");

        for (uint256 i = 0; i < _addressList.length; i++) {
            if (_quantityList[i] >= minBatchSize) {
                uint _batchCount = _quantityList[i] / minBatchSize;
                uint _reminder = _quantityList[i] % minBatchSize;

                for (uint256 c = 0; c < _batchCount; c++) {
                    _mintNFT(_addressList[i], minBatchSize);
                }

                if (_reminder > 0) {
                    _mintNFT(_addressList[i], _reminder);
                }
            } else {
                _mintNFT(_addressList[i], _quantityList[i]);
            }
        }
    }

    // ===== Setter (owner only) =====

    /** @dev update mint state
     */
    function updateState(State _state) external onlyOwner {
        mintState = _state;
    }

    /** @dev pause the mint
     */
    function pauseMint() external onlyOwner {
        _pause();
    }

    /** @dev unpause the mint
     */
    function unpauseMint() external onlyOwner {
        _unpause();
    }

    /** @dev update baseTokenURI
     */
    function setBaseTokenURI(string memory newTokenURI) external onlyOwner {
        baseTokenURI = newTokenURI;
    }

    /** @dev update wallet address
     */
    function updateWalletAddress(address _newWalletAddress) external onlyOwner {
        walletAddress = _newWalletAddress;
    }

    /** @dev update signer address */
    function updateSignerAddress(address newSignerAddr) external onlyOwner {
        emit SignerAddressUpdated(signerAddress, newSignerAddr);
        signerAddress = newSignerAddr;
    }

    // emergency bypass signature checking
    function updateBypassSignatureChecking(bool _status) external onlyOwner {
        _bypassSignatureChecking = _status;
    }

    // ===== Readonly and Pure Functions =====
    /** @dev get baseTokenURI
     */
    // required override
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /** @dev get token URI */
    // required override
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /** @dev validate signature address
     */
    function isSignedBySigner(
        address _sender,
        string memory _nonce,
        uint256 _quantity,
        bytes memory _signature,
        address signer
    ) private pure returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(_sender, _nonce, _quantity));
        return signer == hash.recover(_signature);
    }

    /** @dev Change the starting token ID*/
    // require override
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}