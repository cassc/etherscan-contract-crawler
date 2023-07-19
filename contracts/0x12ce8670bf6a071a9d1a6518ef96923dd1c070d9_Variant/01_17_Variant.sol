// SPDX-License-Identifier,
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";


contract Variant is ERC721A, PaymentSplitter, Ownable {
    using SafeMath for uint256;
    
    // Sale States
    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;
    
    // Privates
    string private _baseURIextended;
    address private signer = 0x93BEE5bd574d8962cc1E3D29580991EBEe2fF8d6;

    modifier onlyDevOrTeam {
        require(msg.sender == 0xa1c490DE6383d3F5d422AF3FAC778799f97b1314 || msg.sender == 0x9126d1FD494d88239145A8b5b3418D2E5aC2D53b);
        _;
    }

    // Shares
	address[] private addressList = [
        0x327c944F1Eb1b49cD37AD1024A45E1a569266425,
        0xD1FC01a85D6Fd598b2a13f76fE09578e20e1a91D,
        0x0bC1CE50B227ff15E51071b24fc7B75343995611,
        0x568Ee1026D4F72054EF7A706b6d2aB49ef4Fc17A,
        0xc2770Fa7c8FFCcC7a7C1EF7Ac707149287C16921,
        0xab4653670A701D4f7EF7dB4C82801534b9Eeb71E,
        0x07603969F4ee7994161FEFDc3a989f179b13552b,
        0x0fF21E5d760e1ACE4B9Cf46F334405b557b58231
	];

    // Out of 1,000,000 for 4 decimals
	uint[] private shareList = [
        703750,
        67500,
        67500,
        60000,
        28125,
        28125,
        22500,
        22500
	];
    
    // Constants
    uint256 public MAX_SUPPLY = 7777;
    uint256 public PRICE_PER_TOKEN = 0.0888 ether;
    uint256 private maxMintPerWalletPresale = 2;
	uint256 private maxMintPerTxPresale = 2;
	uint256 private maxMintPerTxPublic= 3;
    uint256 private maxMintPerWallet = 6;

    // Mappings
    mapping(address => uint256) public numMintedPerPerson;
    
    constructor() ERC721A("Variant", "VRNT") PaymentSplitter(addressList, shareList) {}

    function presaleMint(address _address, bytes calldata _voucher, uint256 _tokenAmount) external payable {
        uint256 ts = totalSupply();
        require(isPresaleActive, "Presale is not active");
  		require(_tokenAmount <= maxMintPerTxPresale, "You can mint max 2 tokens");
        require(ts + _tokenAmount <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(msg.value >= PRICE_PER_TOKEN * _tokenAmount, "Ether value sent is not correct");
        require(msg.sender == _address, "Not your voucher");
    	require(numMintedPerPerson[_address] + _tokenAmount <= maxMintPerTxPresale, "Cannot mint more than 6 per wallet");

        bytes32 hash = keccak256(
            abi.encodePacked(_address)
        );
        require(_verifySignature(signer, hash, _voucher), "Invalid voucher");

        _safeMint(_address, _tokenAmount);
        numMintedPerPerson[_address] += _tokenAmount;
    }


 	function mintPublic(uint256 _tokenAmount) public payable {
        uint256 ts = totalSupply();
        require(isPublicSaleActive,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
        require(_tokenAmount <= maxMintPerTxPublic);
        require(ts + _tokenAmount <= MAX_SUPPLY, "Mint less");
        require(msg.value >= PRICE_PER_TOKEN * _tokenAmount, "ETH input is wrong");
        require(numMintedPerPerson[msg.sender] + _tokenAmount <= maxMintPerWallet, "Cannot mint more than 6 per wallet");

        _safeMint(msg.sender, _tokenAmount);
        numMintedPerPerson[msg.sender] += _tokenAmount;
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) private pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    // Set the price
    function setPrice(uint256 _newPrice) external onlyDevOrTeam {
        PRICE_PER_TOKEN = _newPrice;
    }

    // Set the supply
    function setSupply(uint256 _newSupply) external onlyDevOrTeam {
        MAX_SUPPLY = _newSupply;
    }

    // Allowed Minting
    function setIsPresaleActive(bool _isPresaleActive) external onlyDevOrTeam {
        isPresaleActive = _isPresaleActive;
    }

    function setSigner(address _signer) external onlyDevOrTeam {
        signer = _signer;
    }
    
    // Public Minting
    function setPublicSaleState(bool _isPublicSaleActive) external onlyDevOrTeam {
        isPublicSaleActive = _isPublicSaleActive;
    }

    // Overrides
    function setBaseURI(string memory baseURI_) external onlyDevOrTeam {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    // Reserve
 	function reserve(address addr, uint256 qty) public onlyDevOrTeam {
  	    uint256 s = totalSupply();
	    require(s + qty <= MAX_SUPPLY, "Mint less");
        _safeMint(addr, qty);
    }

    // Max switches
	function setMaxPerWallet(uint256 _newMaxMintAmount) public onlyDevOrTeam {
	    maxMintPerWallet = _newMaxMintAmount;
	}

    // Max switches
	function setMaxPerWalletPresale(uint256 _newMaxMintAmount) public onlyDevOrTeam {
	    maxMintPerWalletPresale = _newMaxMintAmount;
	}

	function setMaxPerTxPresale(uint256 _newMaxAmount) public onlyDevOrTeam {
	    maxMintPerTxPresale = _newMaxAmount;
	}

	function setMaxPerTxPublic(uint256 _newMaxAmount) public onlyDevOrTeam {
	    maxMintPerTxPublic= _newMaxAmount;
	}
}