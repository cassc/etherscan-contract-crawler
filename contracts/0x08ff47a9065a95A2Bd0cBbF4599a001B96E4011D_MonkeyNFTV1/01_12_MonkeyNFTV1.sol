pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// THIS IS THE ONE WE NEED: https://forum.openzeppelin.com/t/sign-it-like-you-mean-it-creating-and-verifying-ethereum-signatures/697

contract MonkeyNFTV1 is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Optional mapping for token URIs
    // Elements x <= 100 are element 1.
    // Elements 100 < x <= 200 are 2.
    // Elements 200 < x <= 300 are 3.
    // Elements 900 < x <= 1000 are 10.
    mapping(uint256 => string) private _baseURIForTokenRange;
     
    // The current number of tokens already minted. 
    uint public numberOfTotalMints;

    // How many tokens do we allow in total?
    uint public maxNumberOfTotalMints;

    // We release tokens in batches. What is the current max number of tokens allowed for minting? This will be updated over time.
    uint public currentTokenNumberLimit; 

    constructor() ERC721("NFTJungleApes S1", "NJAS1") 
    {
        numberOfTotalMints = 0;
        maxNumberOfTotalMints = 1000;
        currentTokenNumberLimit = 1000;

        // We will append "https://" to the front and "/apes/metadata" to the end.
        _setBaseURIForTokenRange(1, "nft-lion-cubs-images.s3.eu-west-2.amazonaws.com");
        _setBaseURIForTokenRange(2, "nft-lion-cubs-images.s3.eu-west-2.amazonaws.com");
        _setBaseURIForTokenRange(3, "nft-lion-cubs-images.s3.eu-west-2.amazonaws.com");
        _setBaseURIForTokenRange(4, "nft-lion-cubs-images.s3.eu-west-2.amazonaws.com");
        _setBaseURIForTokenRange(5, "nft-lion-cubs-images.s3.eu-west-2.amazonaws.com");
        _setBaseURIForTokenRange(6, "nft-lion-cubs-images.s3.eu-west-2.amazonaws.com");
        _setBaseURIForTokenRange(7, "nft-lion-cubs-images.s3.eu-west-2.amazonaws.com");
        _setBaseURIForTokenRange(8, "nft-lion-cubs-images.s3.eu-west-2.amazonaws.com");
        _setBaseURIForTokenRange(9, "nft-lion-cubs-images.s3.eu-west-2.amazonaws.com");
        _setBaseURIForTokenRange(10, "nft-lion-cubs-images.s3.eu-west-2.amazonaws.com");
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) 
    {
        _requireMinted(tokenId);

        string memory baseURI = getBaseURIForTokenId(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked("https://", baseURI, "/apes/metadata/", Strings.toString(tokenId), ".json")) : "";
    }

    // Elements x <= 100 are element 1.
    // Elements 100 < x <= 200 are 2.
    // Elements 200 < x <= 300 are 3.
    // Elements 900 < x <= 1000 are 10.
    function getBaseURIForTokenId(uint256 tokenId) public view virtual returns (string memory) 
    {
        require(tokenId > 0, "Token Id must be > 0.");
        uint256 localToken = tokenId - 1;
        uint256 rangeIndex = localToken / 100;
        rangeIndex = rangeIndex + 1;
        return getBaseURIForTokenRange(rangeIndex); 
    }


    function updateBaseURIForTokenRange(uint256 rangeIndex, string memory baseURI) public onlyOwner
    {
        _setBaseURIForTokenRange(rangeIndex, baseURI);
    }

    function getBaseURIForTokenRange(uint256 rangeIndex) public view returns (string memory)
    {
        uint256 localIndex = rangeIndex;
        if (localIndex < 1)
        {
            localIndex = 1;
        }
        if (localIndex > 10)
        {
            localIndex = 10;
        }
        return _baseURIForTokenRange[localIndex];
    }

    
    function _setBaseURIForTokenRange(uint256 rangeIndex, string memory baseURI) internal virtual 
    {
        _baseURIForTokenRange[rangeIndex] = baseURI;
    }

    function stringToUint(string memory numString) public pure returns(uint) 
    {
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }

    /* 0.07 Eth = 70000000000000000 WEI */
    function mintNFT(address recipient,
                     uint256 weiPriceFromServerInt,
                     uint256 numberOfMintsInt,
                     bytes memory sig)
        public payable
        returns (uint256)
    {
        // uint256 numberOfMintsInt = stringToUint(numberOfMints);
        uint localNumberOfTotalMints = numberOfTotalMints;
        uint localMaxNumberOfTotalMints = maxNumberOfTotalMints;
        uint localCurrentTokenNumberLimit = currentTokenNumberLimit;

        require((localNumberOfTotalMints + numberOfMintsInt) <= localMaxNumberOfTotalMints, "Not enough tokens left.");
        
        require((localNumberOfTotalMints + numberOfMintsInt) <= localCurrentTokenNumberLimit, "Not enough tokens left in batch.");

        // uint256 expectedMintPriceInt = stringToUint(weiPriceFromServer);
        require(msg.value >= weiPriceFromServerInt, "Provide enough ETH.");

        bool isValid = isValidData(recipient, weiPriceFromServerInt, numberOfMintsInt, sig);

        require(isValid, "The minting data was invalid.");

        return mintInternal(recipient, numberOfMintsInt);
    }



    function mintInternal(address recipient,
                          uint256 numberOfMints) internal returns (uint256)
    {
        for (uint counter = 0; counter < numberOfMints; counter++)
        {
            numberOfTotalMints = numberOfTotalMints + 1;

            _tokenIds.increment();

            uint256 newItemId = _tokenIds.current();
            _mint(recipient, newItemId);
        }
        uint256 tokensOwned = balanceOf(recipient);
        return tokensOwned;
    }

    function mintOwnerOnly(address recipient,
                           uint256 numberOfMints) public onlyOwner returns (uint256)
    {
        return mintInternal(recipient, numberOfMints);
    }

    function ownerTransfer(address payable to, uint256 amount) public onlyOwner 
    {
        to.transfer(amount);
    }

    
    function getCurrentTokenNumberLimit() public view returns(uint) 
    {
        return currentTokenNumberLimit;
    }
    
    function setCurrentTokenNumberLimit(uint newValue) public onlyOwner
    {
        currentTokenNumberLimit = newValue;
    }


    
    function getNumberOfTotalMints() public view returns(uint) 
    {
        return numberOfTotalMints;
    }
    
    function setNumberOfTotalMints(uint newValue) public onlyOwner
    {
        numberOfTotalMints = newValue;
    }

    function getMaxNumberOfTotalMints() public view returns(uint) 
    {
        return maxNumberOfTotalMints;
    }
    
    function setMaxNumberOfTotalMints(uint newValue) public onlyOwner
    {
        maxNumberOfTotalMints = newValue;
    }



    function isValidData(address recipientAddress, 
                         uint256 weiPriceFromServer,
                         uint256 numberOfMints,
                         bytes memory sig) internal view returns(bool)
    {
       string memory addressOfBuyer = toAsciiString(recipientAddress);   

       string memory numberOfMintsString = Strings.toString(numberOfMints);

       string memory weiPriceFromServerString = Strings.toString(weiPriceFromServer);

       // When the js script created the original message, it should have converted to lower case and removed the leading "0x" from the addressOfBuyer.
       bytes32 message = keccak256(abi.encodePacked(addressOfBuyer, weiPriceFromServerString, numberOfMintsString));

       return (recoverSigner(message, sig) == owner());
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) 
    {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
       internal
       pure
       returns (address)
    {
       uint8 v;
       bytes32 r;
       bytes32 s;

       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
       internal
       pure
       returns (uint8, bytes32, bytes32)
    {    
       require(sig.length == 65);
       
       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }

       return (v, r, s);
    }
}