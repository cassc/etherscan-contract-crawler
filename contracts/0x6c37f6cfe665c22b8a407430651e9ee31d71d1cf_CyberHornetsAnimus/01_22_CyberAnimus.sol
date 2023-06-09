// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./GDXERC721Batch.sol";
import "../Blimpie/Signed.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract CyberHornets {
	function balanceOf(address owner) external view returns (uint256 balance) {}
} 

contract CyberHornetsAnimus is GDXERC721Batch, Signed {

    using Strings for uint256;

	CyberHornets cyberHornets = CyberHornets(0x821043B51Bd384f2CaA0d09dc136181870B2beA2);

    uint256 public MAX_ORDER = 10;
    uint256 public MAX_SUPPLY = 6666;
    uint256 public PRICE = 0.06 ether;
	
	uint256 public MAX_PRESALE_AMOUNT = 4;
    uint256 public PRE_KNIGHT_PRICE = 0.05 ether;
    uint256 public PRE_COMMON_PRICE = 0.055 ether;

	enum SaleState {
		Paused,
		Presale,
		Public
	}
		
	bool isVerified;
	
    SaleState public saleState = SaleState.Paused;

    string private _baseTokenURI = "";
    string private _tokenURISuffix = "";

    mapping(address => uint256) public presaleMap;
	mapping(uint => uint) public hornetsMinted;

    address[] addresses = [
		0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a,
		0x0ecAf65655901e0b1BabDb9d7A674De7c824853d,
		0x1f01ee624c646Bf9f510d004BdB90d53Bed24642,
		0x2669Ac0238c3f0Fd48ac5D5381A95B8689879843,
		0x8060ec8fFAEf3021d83bbc7F5D88b262A52e449e,
		0xb7bb98Bb5CF07F9B6d1528d0973979773a273288
    ];
    uint256[] splits = [7, 6, 6, 6, 4, 71];
	
	mapping(address => bool) public Knights;

    constructor() GDXERC721("Cyber Hornets Animus", "ANIMUS") {
        Knights[ 0x0ecAf65655901e0b1BabDb9d7A674De7c824853d ] = true;
		Knights[ 0x99044a1FEE6f24AAD3b0144fA52e03406F8EB1Ce ] = true;
		Knights[ 0xB7b74567850522fd84CFE8fef30762423987D9a8 ] = true;
		Knights[ 0x4d6Edc3579636b47Edfe405cBC443851DbB27474 ] = true;
		Knights[ 0x97e7C82cD52303bc6f60BB9366af081665229F64 ] = true;
		Knights[ 0xC1da309F85eD397A942f9bF212cdd63110E61515 ] = true;
		Knights[ 0x8060ec8fFAEf3021d83bbc7F5D88b262A52e449e ] = true;
		Knights[ 0x3d24F913036138D8CC2A6cb1Befc9c899709E89C ] = true;
		Knights[ 0xa251C3b888D77419d7104A90739493FFdF25FF7F ] = true;
		Knights[ 0x79F4F419EDa7769d5058e0d7De91fFe1f584CBD0 ] = true;
    }

    //safety first
    fallback() external payable {}

    receive() external payable {}

    function withdraw() external onlyDelegates {
        require(address(this).balance > 0);
        uint256 bal = address(this).balance;
        for (uint256 i; i < addresses.length; i++) {
            require(payable(addresses[i]).send((bal / 100) * splits[i]));
        }
    }

    //view
    function getTokensByOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return walletOfOwner(owner);
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    _tokenURISuffix
                )
            );
    }

    //payable
	function mintPresale(uint256 quantity, bytes calldata signature) external payable {
		require(saleState >= SaleState.Presale, "Presale not active");
		require(quantity + presaleMap[msg.sender] <= MAX_PRESALE_AMOUNT, "Order exceeds presale allowance");

        uint256 supply = totalSupply();
        require(supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply");
		
        if (Knights[ msg.sender ]) {
            require(msg.value >= PRE_KNIGHT_PRICE * quantity, "Not enough ETH sent");
			if (isVerified)
                verifySignature(quantity.toString(), signature);
		} else {
			require(msg.value >= PRE_COMMON_PRICE * quantity, "Not enough ETH sent");

            if( signature.length < 32 )
			    require( cyberHornets.balanceOf(msg.sender) > 0, "Address not authorized" );
            else if (isVerified)
                verifySignature(quantity.toString(), signature);
        }
		
		presaleMap[msg.sender] = presaleMap[msg.sender] + quantity;

        unchecked {
            for (uint256 i; i < quantity; i++) {
                _mint(msg.sender, supply++);
            }
        }
    }
	
	
    function mint(uint256 quantity) external payable {
        require(saleState == SaleState.Public, "Public sale not active");
        require(quantity <= MAX_ORDER, "Order too big");
        
		uint256 supply = totalSupply();
        require(supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply");
		require(msg.value >= PRICE * quantity, "Not enough ETH sent");
		
		unchecked {
            for (uint256 i; i < quantity; i++) {
                _mint(msg.sender, supply++);
            }
        }
    }

    //onlyDelegates
    function mintTo(uint256[] calldata quantity, address[] calldata recipient)
        external
        payable
        onlyDelegates
    {
        require(
            quantity.length == recipient.length,
            "Must provide equal quantities and recipients"
        );

        uint256 totalQuantity;
        uint256 supply = totalSupply();
        for (uint256 i; i < quantity.length; i++) {
            totalQuantity += quantity[i];
        }
        require(
            supply + totalQuantity <= MAX_SUPPLY,
            "Mint/order exceeds supply"
        );

        unchecked {
            for (uint256 i = 0; i < recipient.length; i++) {
                for (uint256 j = 0; j < quantity[i]; j++) {
                    _mint(recipient[i], supply++);
                }
            }
        }
    }

    // In case of emergency
    function setWithdrawalData(
        address[] calldata _addr,
        uint256[] calldata _splits
    ) external onlyDelegates {
        require(
            _addr.length == splits.length,
            "Mismatched number of addresses and splits."
        );
        addresses = _addr;
        splits = _splits;
    }

    function setActive(
        SaleState saleState_
    ) external onlyDelegates {

        if (saleState != saleState_)
            saleState = saleState_;

    }

	function setHornetAddress(address hornetAddress) public onlyDelegates {
		cyberHornets = CyberHornets(hornetAddress);
	}

    function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix)
        external
        onlyDelegates
    {
        _baseTokenURI = _newBaseURI;
        _tokenURISuffix = _newSuffix;
    }

    function setMax(uint256 maxOrder, uint256 maxSupply)
        external
        onlyDelegates
    {
        require(
            maxSupply >= totalSupply(),
            "Specified supply is lower than current balance"
        );

        if (MAX_ORDER != maxOrder) MAX_ORDER = maxOrder;

        if (MAX_SUPPLY != maxSupply) MAX_SUPPLY = maxSupply;
    }

    function setVerified(bool verified_) external onlyDelegates {
        if (isVerified != verified_) isVerified = verified_;
    }

    function setPrice(uint256 price) external onlyDelegates {
        if (PRICE != price) PRICE = price;
    }

    //internal
    function _mint(address to, uint256 tokenId) internal override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}