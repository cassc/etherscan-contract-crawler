//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
   ,---.                      ,-.-.   ,---.                    ,-,--.         ,--.--------.  .=-.-.               ,----.               
 .--.'  \       _.-. ,-..-.-./  \==\.--.'  \   ,--.-.  .-,--.,-.'-  _\       /==/,  -   , -\/==/_ /.-.,.---.   ,-.--` , \  _,..---._   
 \==\-/\ \    .-,.'| |, \=/\=|- |==|\==\-/\ \ /==/- / /=/_ //==/_ ,_.'       \==\.-.  - ,-./==|, |/==/  `   \ |==|-  _.-`/==/,   -  \  
 /==/-|_\ |  |==|, | |- |/ |/ , /==//==/-|_\ |\==\, \/=/. / \==\  \           `--`\==\- \  |==|  |==|-, .=., ||==|   `.-.|==|   _   _\ 
 \==\,   - \ |==|- |  \, ,     _|==|\==\,   - \\==\  \/ -/   \==\ -\               \==\_ \ |==|- |==|   '='  /==/_ ,    /|==|  .=.   | 
 /==/ -   ,| |==|, |  | -  -  , |==|/==/ -   ,| |==|  ,_/    _\==\ ,\              |==|- | |==| ,|==|- ,   .'|==|    .-' |==|,|   | -| 
/==/-  /\ - \|==|- `-._\  ,  - /==//==/-  /\ - \\==\-, /    /==/\/ _ |             |==|, | |==|- |==|_  . ,'.|==|_  ,`-._|==|  '='   / 
\==\ _.\=\.-'/==/ - , ,/-  /\ /==/ \==\ _.\=\.-'/==/._/     \==\ - , /             /==/ -/ /==/. /==/  /\ ,  )==/ ,     /|==|-,   _`/  
 `--`        `--`-----'`--`  `--`   `--`        `--`-`       `--`---'              `--`--` `--`-``--`-`--`--'`--`-----`` `-.`.____.'   
*/
interface ISnoozeToken {
    function updateRewards(
        address _from,
        address _to,
        uint256 _quantity
    ) external;
}

contract AlwaysTired is ERC721A, Ownable, Pausable, ReentrancyGuard {
    enum Mode {
        PRE_MINT,
        MINT
    }

    uint256 public constant OG_PRICE = 0.02 ether;
    uint256 public constant WHITELIST_PRICE = 0.02 ether;
    uint256 public constant PRICE = 0.03 ether;

    uint16 public constant MAX_SUPPLY = 7777;

    uint8 public constant OG_LIMIT = 4;
    uint8 public constant WHITELIST_LIMIT = 3;
    uint8 public constant FREEMINT_LIMIT = 1;

    Mode public mode = Mode.PRE_MINT;

    string public baseURI;
    string public placeholderURI;

    bool public revealed = false;

    bytes32 public ogRoot;
    bytes32 public whitelistRoot;
    bytes32 public freemintRoot;

    ISnoozeToken public snoozeToken = ISnoozeToken(address(0));

    mapping(address => uint16) public ogMints;
    mapping(address => uint16) public whitelistMints;
    mapping(address => uint16) public freeMints;
    mapping(address => uint16) public publicMints;

    modifier isValidAmount(uint16 _amount) {
        require(_amount > 0, "Invalid amount");
        require(
            totalSupply() + _amount <= MAX_SUPPLY,
            "Amount exceeds max supply"
        );
        _;
    }

    modifier isMode(Mode _mode) {
        require(mode == _mode, "Invalid mode");
        _;
    }

    constructor(
        bytes32 _ogRoot,
        bytes32 _whitelistRoot,
        bytes32 _freemintRoot,
        string memory _placeholderURI
    ) ERC721A("AlwaysTired", "ALWT") {
        ogRoot = _ogRoot;
        whitelistRoot = _whitelistRoot;
        freemintRoot = _freemintRoot;
        placeholderURI = _placeholderURI;
        _pause();
    }

    // external

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setMode(Mode _mode) external onlyOwner {
        mode = _mode;
    }

    function reveal(string calldata baseURI_) external onlyOwner {
        revealed = true;
        baseURI = baseURI_;
    }

    function setOgRoot(bytes32 _ogRoot) external onlyOwner {
        ogRoot = _ogRoot;
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function setFreemintRoot(bytes32 _freemintRoot) external onlyOwner {
        freemintRoot = _freemintRoot;
    }

    function setSnoozeToken(address _snoozeToken) external onlyOwner {
        snoozeToken = ISnoozeToken(address(_snoozeToken));
    }

    function airdrop(address[] calldata _addresses, uint16 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_amount > 0, "Invalid amount");
        require(
            totalSupply() + _amount * _addresses.length <= MAX_SUPPLY,
            "Amount exceeds max supply"
        );
        for (uint16 i = 0; i < _addresses.length; ) {
            require(_addresses[i] != address(0), "Invalid address");
            _safeMint(_addresses[i], _amount);
            unchecked {
                i++;
            }
        }
    }

    function mintOg(bytes32[] calldata _ogProof, uint16 _amount)
        external
        payable
        whenNotPaused
        nonReentrant
        isMode(Mode.PRE_MINT)
        isValidAmount(_amount)
    {
        require(
            msg.value >= OG_PRICE * _amount,
            "Insufficient ether for mint amount"
        );
        require(
            MerkleProof.verify(
                _ogProof,
                ogRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "No OG allowed"
        );
        require(ogMints[msg.sender] < OG_LIMIT, "OG limit reached");
        require(
            ogMints[msg.sender] + _amount <= OG_LIMIT,
            "Amount exceeds OG limit"
        );
        _safeMint(msg.sender, _amount);
        unchecked {
            ogMints[msg.sender] += _amount;
        }
    }

    function mintWhitelist(bytes32[] calldata _whitelistProof, uint16 _amount)
        external
        payable
        whenNotPaused
        nonReentrant
        isMode(Mode.PRE_MINT)
        isValidAmount(_amount)
    {
        require(
            msg.value >= WHITELIST_PRICE * _amount,
            "Insufficient ether for mint amount"
        );
        require(
            MerkleProof.verify(
                _whitelistProof,
                whitelistRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on whitelist"
        );
        require(
            whitelistMints[msg.sender] < WHITELIST_LIMIT,
            "Whitelist limit reached"
        );
        require(
            whitelistMints[msg.sender] + _amount <= WHITELIST_LIMIT,
            "Amount exceeds whitelist limit"
        );
        _safeMint(msg.sender, _amount);
        unchecked {
            whitelistMints[msg.sender] += _amount;
        }
    }

    function mintFreemint(bytes32[] calldata _freemintProof, uint16 _amount)
        external
        payable
        whenNotPaused
        nonReentrant
        isMode(Mode.MINT)
        isValidAmount(_amount)
    {
        require(
            MerkleProof.verify(
                _freemintProof,
                freemintRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "No freemint allowed"
        );
        require(
            freeMints[msg.sender] < FREEMINT_LIMIT,
            "Freemint limit reached"
        );
        require(
            freeMints[msg.sender] + _amount <= FREEMINT_LIMIT,
            "Amount exceeds freemint limit"
        );
        _safeMint(msg.sender, _amount);
        unchecked {
            freeMints[msg.sender] += _amount;
        }
    }

    function mintPublic(uint16 _amount)
        external
        payable
        whenNotPaused
        nonReentrant
        isMode(Mode.MINT)
        isValidAmount(_amount)
    {
        require(
            msg.value >= PRICE * _amount,
            "Insufficient ether for mint amount"
        );
        _safeMint(msg.sender, _amount);
        unchecked {
            publicMints[msg.sender] += _amount;
        }
    }

    function withdraw(address payable _address, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_address != address(0), "Invalid address");
        require(_amount > 0, "Invalid amount");
        require(_amount <= address(this).balance, "Amount exceeds balance");
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    function withdrawAll(address payable _address)
        external
        onlyOwner
        nonReentrant
    {
        require(_address != address(0), "Invalid address");
        (bool success, ) = _address.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    // public

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!revealed) {
            return string.concat(placeholderURI, Strings.toString(_tokenId));
        } else {
            return super.tokenURI(_tokenId);
        }
    }

    function totalMints(address _address) public view returns (uint16) {
        unchecked {
            return
                ogMints[_address] +
                whitelistMints[_address] +
                freeMints[_address] +
                publicMints[_address];
        }
    }

    // internal

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 startTokenId_,
        uint256 _quantity
    ) internal virtual override {
        super._beforeTokenTransfers(_from, _to, startTokenId_, _quantity);
        if (address(snoozeToken) != address(0)) {
            snoozeToken.updateRewards(_from, _to, _quantity);
        }
    }
}