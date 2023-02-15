//SPDX-License-Identifier: MIT  
pragma solidity ^0.8.12;  
  
import "erc721a/contracts/ERC721A.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

error MintNotStarted();
error InsufficientPayment();
error ExceedSupply();
error ExceedMaxPerWallet();

contract SatoshiMinter is ERC721A , Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Math for uint256;
    using Strings for string;
    
    // VARIABLES
    uint16 constant devSupply = 5;
    uint16 constant collectionSupply = 100;
    
    uint256 public currentSupply = 0;
    uint256 public devMinted = 0;

    bool public mintStarted;

    uint8 private maxItemsPerWallet = 1;

    uint256 private mintPrice = 0 ether;

    // Constructor will be called on contract creation
    constructor() ERC721A("SatoshiMinter", "SM") {}
  
    // MODIFIERS
    modifier whenMint() {
        if (!mintStarted) revert MintNotStarted();
        _;
    }

    // DEV MINT
    function devMint(uint8 quantity) external onlyOwner nonReentrant {
        if((devMinted + quantity) > devSupply) revert ExceedSupply();

        _mint(msg.sender, quantity);       
        devMinted++; 
        currentSupply++;
    }

    function mint(uint256 quantity) external payable nonReentrant whenMint {
        if(msg.value < mintPrice * quantity) revert InsufficientPayment();
        if(totalSupply() + quantity > ( collectionSupply - (devSupply - devMinted))) revert ExceedSupply();
        if(_numberMinted(msg.sender) + quantity > maxItemsPerWallet) revert ExceedMaxPerWallet();
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(msg.sender, quantity);
        currentSupply++;
    }

    // WITHDRAW
    function withdraw() external onlyOwner nonReentrant {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    // SETTERS
    function startMint() external onlyOwner {
        mintStarted = !mintStarted;
    }

    /**
     * @dev return tokenURI, image SVG data in it.
     */

    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        uint256 tokenIdPlusOne = tokenId + 1;
        uint256 number_of_rows = 0;
        if ( tokenIdPlusOne <= 1 ) {
            number_of_rows = 1;
        }
        else if ( tokenIdPlusOne <= 4 ) {
            number_of_rows = 2;
        }
        else if ( tokenIdPlusOne <= 9 ) {
            number_of_rows = 3;
        }
        else if ( tokenIdPlusOne <= 16 ) {
            number_of_rows = 4;
        }
        else if ( tokenIdPlusOne <= 25 ) {
            number_of_rows = 5;
        }
        else if ( tokenIdPlusOne <= 36 ) {
            number_of_rows = 6;
        }
        else if ( tokenIdPlusOne <= 49 ) {
            number_of_rows = 7;
        }
        else if ( tokenIdPlusOne <= 64 ) {
            number_of_rows = 8;
        }
        else if ( tokenIdPlusOne <= 81 ) {
            number_of_rows = 9;
        }
        else if ( tokenIdPlusOne <= 100 ) {
            number_of_rows = 10;
        }
        uint256 scale_max = 70000;
        uint256 scale = SafeMath.div( scale_max, number_of_rows );
        uint256 viewport = 500;
        uint256 scaled_viewport = SafeMath.div( SafeMath.mul( viewport, scale ), 1 );
        return _generateSVG(tokenIdPlusOne, number_of_rows, scale, scaled_viewport);
    }

    function _generateSVG(uint256 tokenId, uint256 number_of_rows, uint256 scale, uint256 scaled_viewport)  private pure  returns (string memory) {
        uint256 count = 0;
        string memory scalePrefix = '0.';

        if ( scale < 10000 ) {
            scalePrefix = '0.0';
        }

        string[3] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500"><rect x="0" y="0" height="500" width="500" fill="transparent" rx="50"/><g align="center" transform="translate(50,50)"><rect id="rounded-rectangle" x="0" y="0" height="400" width="400" rx="50" fill="#F6EECB" /><g transform="translate(25,25)"><rect id="rounded-rectangle" height="350" width="350" rx="50" fill="transparent"/>';
        parts[1] = '';
        if (number_of_rows > 1) {
            for(uint256 i = 0; i < number_of_rows; i++ ) {
                for(uint256 j = 0; j < number_of_rows; j++ ) {
                    if (count < tokenId) {
                        uint256 t1 = SafeMath.div(SafeMath.mul(scaled_viewport, j), 100000);
                        uint256 t2 = SafeMath.div(SafeMath.mul(scaled_viewport, i), 100000);
                        parts[1] = string(abi.encodePacked(parts[1], '<g transform="translate(', Strings.toString(t1), ', ', Strings.toString(t2), ') scale(', scalePrefix, Strings.toString(scale), ')"><svg data-name="Layer 1" viewBox="-10 -10 380 380" xmlns="http://www.w3.org/2000/svg"><g transform="translate(0)"><circle class="cls-1" cx="180" cy="180" r="179" fill="#f8991d"/><rect class="cls-2" transform="translate(21.82 -52.79) rotate(14.87)" x="201.48" y="37.16" width="23.49" height="40.14" fill="#fff"/><rect class="cls-2" transform="translate(83.82 -27.36) rotate(14.87)" x="135.03" y="287.5" width="23.49" height="40.14" fill="#fff"/><rect class="cls-2" transform="translate(364.26 -36.11) rotate(104.87)" x="184.27" y="38.29" width="23.49" height="167.49" fill="#fff"/><rect class="cls-2" transform="translate(402.22 54.61) rotate(104.87)" x="168.36" y="98.26" width="23.49" height="167.49" fill="#fff"/><rect class="cls-2" transform="translate(439.1 142.78) rotate(104.87)" x="152.89" y="156.52" width="23.49" height="167.49" fill="#fff"/></g></svg></g>'));

                        count++;
                    }
                }
            }
        }
        else {
            string memory p1 = '<g transform="scale(';
            string memory p2 =  ')"><svg align="center" data-name="Layer 1" viewBox="0 0 360 360" xmlns="http://www.w3.org/2000/svg"><g transform="translate(0)"><circle class="cls-1" cx="180" cy="180" r="179" fill="#f8991d"/><rect class="cls-2" transform="translate(21.82 -52.79) rotate(14.87)" x="201.48" y="37.16" width="23.49" height="40.14" fill="#fff"/><rect class="cls-2" transform="translate(83.82 -27.36) rotate(14.87)" x="135.03" y="287.5" width="23.49" height="40.14" fill="#fff"/><rect class="cls-2" transform="translate(364.26 -36.11) rotate(104.87)" x="184.27" y="38.29" width="23.49" height="167.49" fill="#fff"/><rect class="cls-2" transform="translate(402.22 54.61) rotate(104.87)" x="168.36" y="98.26" width="23.49" height="167.49" fill="#fff"/><rect class="cls-2" transform="translate(439.1 142.78) rotate(104.87)" x="152.89" y="156.52" width="23.49" height="167.49" fill="#fff"/></g></svg></g>';
            parts[1] = string(abi.encodePacked( p1, scalePrefix, Strings.toString(scale), p2));
        }
        
        parts[2] = '</g></g></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "#', Strings.toString(tokenId), '", "description": "A Ethereum NFT Minted off the Bitcoin Blockchain", "attributes": [{"trait_type": "Number of Satoshi", "value": "', Strings.toString(tokenId), '" }], "image_data": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
}