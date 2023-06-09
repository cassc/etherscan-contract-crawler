// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ITimeCatsLoveEmHateEm.sol";

contract LongNeckieWomenOfTheYearByNylaHayes is ERC721, Ownable {
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");

        _;
    }

    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");

        _;
    }

    uint16 public totalTokens = 1000;
    uint16 public totalSupply = 0;
    uint256 public mintPrice = 0.125 ether;
    string private baseURI =
        "ipfs://Qmek5YTipNcMeo6bj3mxyPDSo4WJV7VwWrPQHByEjzur6H/";
    string private blankTokenURI =
        "ipfs://QmT5cyQ7MsSMfSAE8RcDnG6sb5sSscys21FL4K3M8wZAMF/";
    bool private isRevealed = false;
    bool private isFrozen = false;
    address public signerAddress = 0x2B8CB83a6f86Acc3Ffe5897a02429446c7e2078e;
    address public timeCatsAddress = 0x7581F8E289F00591818f6c467939da7F9ab5A777;

    mapping(address => bool) public didAddressMint;
    mapping(uint16 => uint16) private tokenMatrix;

    constructor() ERC721("LongNeckieWomenOfTheYearByNylaHayes", "LNWOTY") {}

    // ONLY OWNER

    /**
     * @dev Allows to withdraw the Ether in the contract
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        baseURI = _uri;
    }

    /**
     * @dev Sets the blank token URI for the API that provides the NFT data.
     */
    function setBlankTokenURI(string memory _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        blankTokenURI = _uri;
    }

    /**
     * @dev Sets the mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Give random tokens to the provided address
     */
    function devMintTokensToAddresses(address[] memory _addresses)
        external
        onlyOwner
    {
        require(
            getAvailableTokens() >= _addresses.length,
            "No tokens left to be minted"
        );

        uint16 tmpTotalMintedTokens = totalSupply;
        totalSupply += uint16(_addresses.length);

        for (uint256 i; i < _addresses.length; i++) {
            _mint(_addresses[i], _getTokenToBeMinted(tmpTotalMintedTokens));
            tmpTotalMintedTokens++;
        }
    }

    /**
     * @dev Set the total amount of tokens
     */
    function setTotalTokens(uint16 _totalTokens)
        external
        onlyOwner
        contractIsNotFrozen
    {
        totalTokens = _totalTokens;
    }

    /**
     * @dev Sets the isRevealed variable to true
     */
    function revealDrop() external onlyOwner {
        isRevealed = true;
    }

    /**
     * @dev Sets the isFrozen variable to true
     */
    function freezeSmartContract() external onlyOwner {
        isFrozen = true;
    }

    /**
     * @dev Sets the address that generates the signatures for whitelisting
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    /**
     * @dev Sets the address of the TimeCatsLoveEmHateEm smart contract
     */
    function setTimeCatsAddress(address _timeCatsAddress) external onlyOwner {
        timeCatsAddress = _timeCatsAddress;
    }

    // END ONLY OWNER

    /**
     * @dev Mint a token
     */
    function mint(
        uint256 _fromTimestamp,
        uint256 _toTimestamp,
        uint256 _catId,
        bool _needsCat,
        bytes calldata _signature
    ) external payable callerIsUser {
        bytes32 messageHash = generateMessageHash(
            msg.sender,
            _fromTimestamp,
            _toTimestamp,
            _needsCat
        );
        address recoveredWallet = ECDSA.recover(messageHash, _signature);
        require(
            recoveredWallet == signerAddress,
            "Invalid signature for the caller"
        );
        require(block.timestamp >= _fromTimestamp, "Too early to mint");
        require(block.timestamp <= _toTimestamp, "The signature has expired");

        require(getAvailableTokens() > 0, "No tokens left to be minted");

        require(msg.value >= mintPrice, "Not enough Ether to mint the token");

        require(!didAddressMint[msg.sender], "Caller cannot mint more tokens");

        if (_needsCat) {
            ITimeCatsLoveEmHateEm catsContract = ITimeCatsLoveEmHateEm(
                timeCatsAddress
            );

            require(
                msg.sender == catsContract.ownerOf(_catId),
                "Caller does not own the given cat id"
            );

            catsContract.setAsUsed(_catId);
        }

        didAddressMint[msg.sender] = true;

        _mint(msg.sender, _getTokenToBeMinted(totalSupply));

        totalSupply++;
    }

    /**
     * @dev Returns the tokenId by index
     */
    function tokenByIndex(uint256 tokenId) external view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        return tokenId;
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    function getAvailableTokens() public view returns (uint16) {
        return totalTokens - totalSupply;
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available token to be minted
     */
    function _getTokenToBeMinted(uint16 _totalMintedTokens)
        private
        returns (uint16)
    {
        uint16 maxIndex = totalTokens - _totalMintedTokens;
        uint16 random = _getRandomNumber(maxIndex, _totalMintedTokens);

        uint16 tokenId = tokenMatrix[random];
        if (tokenMatrix[random] == 0) {
            tokenId = random;
        }

        tokenMatrix[maxIndex - 1] == 0
            ? tokenMatrix[random] = maxIndex - 1
            : tokenMatrix[random] = tokenMatrix[maxIndex - 1];

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint16 _upper, uint16 _totalMintedTokens)
        private
        view
        returns (uint16)
    {
        uint16 random = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _totalMintedTokens,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            )
        );

        return random % _upper;
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (!isRevealed) {
            return blankTokenURI;
        }

        return baseURI;
    }

    /**
     * @dev Generate a message hash for the given parameters
     */
    function generateMessageHash(
        address _address,
        uint256 _fromTimestamp,
        uint256 _toTimestamp,
        bool _needsCat
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n85",
                    _address,
                    _fromTimestamp,
                    _toTimestamp,
                    _needsCat
                )
            );
    }
}