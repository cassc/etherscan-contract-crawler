// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
pragma abicoder v2;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FATTIES is ERC721A, Ownable {
    using Strings for uint256;

    struct PresaleVoucher {
        address to;
        address verifyingContract;
        uint256 presale;
    }
    
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public PRICE_PER_TOKEN = 0.01 ether;

    uint256 public constant MAX_PRESALE_MINT = 5;
    uint256 public constant MAX_MINT = 20;
    uint256 public constant MAX_MINT_PER_FREN = 10;

    uint256 public presaleActive;
    bool public mintActive;

    address public authorizedSigner;
    string private uri;
    string public PROVENANCE;

    mapping(address => bool) private _frensList;
    mapping(address => uint256) private _mintList;

    event MintEnabled(bool);
    event PresaleEnabled(uint256);

    constructor(
        string memory _name,
        address _authorizedSigner,
        string memory _uri)
        ERC721A(_name, _name) {
        authorizedSigner = _authorizedSigner;
        uri = _uri;
        _frensList[0xCed02D5B8EeCD7041c58F041ffC3Deda57fE63dd] = true;
        _frensList[0x72c56cbAfA4ec4316A44071CCD6606ba3ee6889B] = true;
        _frensList[0x4190c5014F8dC2bE9dCcDfAD1E54Da08337a76A6] = true;
        _frensList[0xF848736D4604b94fd324ac714ca728545b91Ca96] = true;
        _frensList[0x1b50926CD0F7b2C18C707f736a24Ebfa1616CB94] = true;
        _frensList[0xAd847cC63e14872A97e091e63b25fC9286f8CB66] = true;
        _frensList[0x93DE00fa850e9e1bA497D0028F1820F1Aabd3b61] = true;
        _frensList[0x4f706e1987d0181Ca6cE067189f61679b76A890A] = true;
    }

    /**
     * @dev The primary mint function used for general minting.
     */
    function mint_540(uint256 quantity) external payable {
        require(totalSupply() < MAX_SUPPLY, "Sale ended");        
        require(mintActive, "Sale has not started");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough supply for quantity");
        require(_mintList[msg.sender] + quantity <= MAX_MINT, "Over max mint balance");
        require(msg.value >= PRICE_PER_TOKEN * (quantity / 5 * 4 + quantity % 5), "Not enough ETH sent");

        _mintList[msg.sender] += quantity;
       _safeMint(msg.sender, quantity);
    }

    /**
     * @dev The secondary mint function used for presale minting. Whitelist is
     * stored off-chain.
     */
    function presaleMint(uint256 quantity, PresaleVoucher calldata voucher, bytes calldata signature) external payable {
        require(totalSupply() < MAX_SUPPLY, "Sale ended");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough supply for quantity");
        require(_mintList[msg.sender] + quantity <= MAX_PRESALE_MINT, "Over presale max mint balance");
        require(msg.value >= PRICE_PER_TOKEN * (quantity / 5 * 4 + quantity % 5), "Not enough ETH sent");
        
        require(voucher.presale == presaleActive, "Presale not active");
        require(msg.sender == voucher.to, "Invalid presale address");
        require(voucher.verifyingContract == address(this), "Invalid domain contract");

        bytes32 digest = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(
                voucher.to,
                voucher.presale,
                voucher.verifyingContract)));
        address recoveredSigner = ECDSA.recover(digest, signature);
        require(authorizedSigner == recoveredSigner, "Invalid signer");

        _mintList[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }
    
    /**
     * @dev The tertiary mint function used for FRENS minting their max free
     * FATTIES.
     */
    function frenMint(address fren) external {
        require(totalSupply() < MAX_SUPPLY, "Sale ended");
        require(totalSupply() + MAX_MINT_PER_FREN <= MAX_SUPPLY, "Not enough supply for quantity");
        require(_frensList[fren], "FREN is not FREN or already minted as FREN.");
        _frensList[fren] = false;
        _safeMint(fren, MAX_MINT_PER_FREN);
    }

    /**
     * @dev Enable/disable the general mint.
     */
    function setMintState(bool state) external onlyOwner {
        emit MintEnabled(state);
        mintActive = state;
    }

    /**
     * @dev Enable/disable the presale mint.
     */
    function setPresaleState(uint256 state) external onlyOwner {
        emit PresaleEnabled(state);
        presaleActive = state;
    }

    /**
     * @dev The base IPFS uri to the token. Prior to reveal, this will be set
     * to the general pre-reveal batch. After reveal, should point to the
     * batch of FATTIES in all its glory.
     */
    function setTokenUri(string memory tokenUri) external onlyOwner {
        uri = tokenUri;
    }

    /**
     * @dev The hash of the images in the order determined prior to mint.
     */
    function setProvenance(string memory provenance) external onlyOwner {
        PROVENANCE = provenance;
    }

    /**
     * @dev The signer used for authorizing presale minting for an address.
     */
    function setAuthorizedSigner(address signer) external onlyOwner {
        authorizedSigner = signer;
    }

    /**
     * @dev Update the per token price.
     */
    function setPrice(uint256 amount) external onlyOwner {
        PRICE_PER_TOKEN = amount;
    }

    /**
     * @dev Split contract balance between a set of predefined addresses.
     */
    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");

        (bool success1, ) = payable(0xCed02D5B8EeCD7041c58F041ffC3Deda57fE63dd).call{value: (balance / 100) * 30}("");
        (bool success2, ) = payable(0x4190c5014F8dC2bE9dCcDfAD1E54Da08337a76A6).call{value: (balance / 100) * 30}("");
        (bool success3, ) = payable(0xdF5a8E36c42aBEe474842103376Ed61005cd572b).call{value: (balance / 100) * 20}("");
        (bool success4, ) = payable(0x72c56cbAfA4ec4316A44071CCD6606ba3ee6889B).call{value: (balance / 100) * 6}("");
        (bool success5, ) = payable(0xAd847cC63e14872A97e091e63b25fC9286f8CB66).call{value: (balance / 100) * 6}("");
        (bool success6, ) = payable(0xF848736D4604b94fd324ac714ca728545b91Ca96).call{value: (balance / 100) * 4}("");
        (bool success7, ) = payable(0x1b50926CD0F7b2C18C707f736a24Ebfa1616CB94).call{value: (balance / 100) * 4}("");

        require(
            success1 && success2 && success3 && success4 && success5 && success6 && success7,
            "Unable to send value, a recipient may have reverted"
        );
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return string(abi.encodePacked(uri, tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}