// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AussieMates is ERC721, Ownable { 
    using Strings for uint256;
	using Counters for Counters.Counter;
	
	Counters.Counter private supply;
    Counters.Counter private matesPassSupply;
    Counters.Counter private goldlistSupply;
    Counters.Counter private reservedTokensSupply;   

    uint public constant maxSupply = 10000;
    uint public reservedTokens = 1000;
    uint public maxMintAmountPerTx = 6;

    uint256 public price = 50000000000000000; //0.05

    bool public saleIsActive = false;
    bool public presaleIsActive = true;
    bool public passIsActive = false;
    bool public revealed = false;

    string private baseURI;
    string private baseExtension = ".json";
    string private notRevealedUri;
 
    mapping(address => uint16)public matesPassAddresses; 
    mapping(address => bool)public goldlistedAddresses; 
    
    constructor()ERC721("AussieMates", "AM8") {}

    // internal
    function _baseURI()internal view virtual override returns(string memory) {
        return baseURI;
    }

	function totalSupply() public view returns (uint256) {
		return supply.current();
	}

    function totalMatesSupply() public view returns (uint256) {
		return matesPassSupply.current();
	}
    
    function totalGoldlistSupply() public view returns (uint256) {
		return goldlistSupply.current();
	}

    function totalreservedTokensSupply() public view returns (uint256) {
		return reservedTokensSupply.current();
	}

    // public
    function mintToken(uint256 amount)external payable {

        require(supply.current() + amount <= maxSupply - reservedTokens, "Purchase would exceed max supply!");
        require(saleIsActive, "Sale must be active to mint");
        require(amount <= maxMintAmountPerTx, "Max 6 NFTs per transaction");

        if (msg.sender != owner()) {
            if (presaleIsActive == true) {
                require(goldlistedAddresses[msg.sender], "Wallet is not eligible");
                goldlistedAddresses[msg.sender] = false;

                for (uint256 i = 0; i < amount; i++) {
                    goldlistSupply.increment();
                }
            }
            require(msg.value >= price * amount, "Not enough ETH for transaction");
        }

		for (uint256 i = 0; i < amount; i++) {
		  supply.increment();
		  _safeMint(msg.sender, supply.current());
		}
    }

    function mintPassToken()external payable {

        require(passIsActive, "Sale must be active to mint");
        require(reservedTokensSupply.current() + matesPassSupply.current() + matesPassAddresses[msg.sender] <= reservedTokens, "This amount is more than max allowed");
        require(matesPassAddresses[msg.sender] > 0, "You don't have any Mates Passes to convert");

		for (uint256 i = 0; i < matesPassAddresses[msg.sender]; i++) {
		    supply.increment();
            matesPassSupply.increment();
		    _safeMint(msg.sender, supply.current());
		}
        matesPassAddresses[msg.sender] = 0;
    }

    function mintReservedTokens(address to, uint256 amount)external onlyOwner {
            
        require(reservedTokensSupply.current() + matesPassSupply.current() + amount <= reservedTokens, "This amount is more than max allowed");

		for (uint256 i = 0; i < amount; i++) {
		    supply.increment();
            reservedTokensSupply.increment();
		    _safeMint(to, supply.current());
		}
    }

    function changeSaleDetails(uint _maxPerTransaction, uint _price, uint _reservedTokens)external onlyOwner{
        maxMintAmountPerTx = _maxPerTransaction;
        price = _price;
        reservedTokens = _reservedTokens;
        saleIsActive = false;
    }
    
    function flipSaleState()external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState()external onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function flipPassState()external onlyOwner {
        passIsActive = !passIsActive;
    }

    function flipReveal()external onlyOwner {
        revealed = !revealed;
    }

    function withdraw()external {
        require(msg.sender == owner(), "Invalid sender");
        payable(owner()).transfer(address(this).balance);
    }

    function addMatesPass(address[]calldata _accounts, uint16 _amount)external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            matesPassAddresses[_accounts[i]] = _amount;
        }
    }

    function addGoldlist(address[]calldata _accounts, bool _status)external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            goldlistedAddresses[_accounts[i]] = _status;
        }
    }

    ////
    //URI management part
    ////

    function setBaseURI(string memory _newBaseURI)public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI)public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns(string memory) {
            require(
                _exists(tokenId),
                "ERC721Metadata: URI query for nonexistent token");

            if (revealed == false) {
                return notRevealedUri;
            }

            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
}