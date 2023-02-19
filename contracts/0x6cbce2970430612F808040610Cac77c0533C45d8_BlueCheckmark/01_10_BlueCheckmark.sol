// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

error ClaimNotActive();
error MismatchedLengths();
error SaleNotActive();
error MustMintAtLeastOneDay();
error IncorrectEthAmount();
error NonexistentToken();
error TokenNotExpired();
error ProjectNotEligible();
error NotYourToken();
error AlreadyClaimed();
error NotHorrorNovelist();
error NegotiationsConcluded();
error NotAMasterNegotiatooor();
error AlreadyGotThanked();

contract BlueCheckmark is ERC721A, Ownable {
  using Strings for uint256;

  // Blue Checkmarks come in three colors: Gold, Gray, and classic Blue
  enum Colors { BLUE, GRAY, GOLD }

  address public recipient = 0x15322B546e31F5Bfe144C4ae133A9Db6F0059fe3; // Coin Center donation address

  // A tracker for easy lookup of the total amount pushed through this contract to the recipient
  uint public amountDonated = 0;

  // ($20 @ $1700 ETH/USD) / 30 days per month = 20 / 1700 / 30 = 0.000392 ETH per day
  uint256 public pricePerDay = 0.000392 ether;

  bool public claimActive = false;

  bool public saleActive = false;

  // Mapping of Blue Checkmark tokenIDs to their expiration dates as uints (seconds since epoch)
  mapping(uint => uint) public tokenExpirationDates;

  // Mapping of "Blue" checkmarks to their colors
  mapping(uint => Colors) public tokenColors;

  mapping(uint => bool) public tokensFromClaims;

  // Mapping of NFT project addresses to the number of free days of Blue Checkmark their holders can claim
  mapping(IERC721 => uint) claimableProjectsDays;

  // Mapping of NFT project addresses to their token IDs to whether or not their freebies have been claimed yet
  mapping(IERC721 => mapping(uint256 => bool)) claimedProjectTokens;

  constructor() ERC721A("BlueCheckmark", "BLUECHECKMARK") {}

  // Override/expose some underlying ERC721A methods...

  function _startTokenId() override internal view virtual returns (uint256) {
    return 1;
  }

  function totalMinted() public view virtual returns (uint256) {
    return _totalMinted();
  }

  function totalBurned() public view virtual returns (uint256) {
    return _totalBurned();
  }

  function exists(uint256 tokenId) public view virtual returns (bool) {
    return _exists(tokenId);
  }

  // Functions to toggle whether claiming and minting are active

  function flipClaimState() public onlyOwner {
    claimActive = !claimActive;
  }

  function flipSaleState() public onlyOwner {
    saleActive = !saleActive;
  }

  // Claiming + management of claimable projects

  function getClaimableProjectNumDays(address project) public view returns (uint) {
    return claimableProjectsDays[IERC721(project)];
  }

  function addClaimableProject(address project, uint numDays) public onlyOwner {
    claimableProjectsDays[IERC721(project)] = numDays;
  }

  function removeClaimableProject(address project) public onlyOwner {
    delete claimableProjectsDays[IERC721(project)];
  }

  function isClaimAvailable(address project, uint tokenId) public view returns (bool) {
    if(claimableProjectsDays[IERC721(project)] == 0) revert ProjectNotEligible();
    return !claimedProjectTokens[IERC721(project)][tokenId];
  }

  function claimFromProjects(address[] memory projects, uint[] memory projectTokenIds) external payable {
    if(!claimActive) revert ClaimNotActive();
    if(projects.length != projectTokenIds.length) revert MismatchedLengths();

    for(uint i = 0; i < projects.length; i++) {
      IERC721 p = IERC721(projects[i]);
      if(claimableProjectsDays[p] == 0) revert ProjectNotEligible();
      if(p.ownerOf(projectTokenIds[i]) != msg.sender) revert NotYourToken();
      if(claimedProjectTokens[p][projectTokenIds[i]]) revert AlreadyClaimed();

      claimedProjectTokens[p][projectTokenIds[i]] = true;
      uint tokenId = totalMinted() + i + 1;
      uint duration = claimableProjectsDays[p] * (1 days);
      tokenExpirationDates[tokenId] = block.timestamp + duration;
      tokenColors[tokenId] = Colors.BLUE;
      tokensFromClaims[tokenId] = true;
    }

    _mint(msg.sender, projects.length);
  }

  // Minting and management of Blue Checkmarks

  // Returns a random Color with probablities:
  // GOLD: 1%
  // GRAY: 4%
  // BLUE: 95%
  function getRandomColor() public view returns(Colors) {
    uint r = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 100;
    if(r == 0) {
      return Colors.GOLD;
    } else if(r < 5) {
      return Colors.GRAY;
    } else {
      return Colors.BLUE;
    }
  }

  function mint(uint numDays) external payable {
    if(!saleActive) revert SaleNotActive();
    if(numDays == 0) revert MustMintAtLeastOneDay();
    if(msg.value != pricePerDay * numDays) revert IncorrectEthAmount();
		
    uint tokenId = totalMinted() + 1;
    uint duration = numDays * (1 days);
    tokenExpirationDates[tokenId] = block.timestamp + duration;

    // If the user is minting a Blue Checkmark for at least a year, they have a chance
    // of getting a gray or gold rather than the default blue.
    tokenColors[tokenId] = msg.value >= pricePerDay * 180 ? getRandomColor() : Colors.BLUE;

    _mint(msg.sender, 1);
  }

  function extendSubscription(uint tokenId, uint numDays) external payable {
    if(!_exists(tokenId)) revert NonexistentToken();
    if(msg.value != pricePerDay * numDays) revert IncorrectEthAmount();

    // There is no check for if msg.sender owns the Blue Checkmark for tokenId so anyone
    // can pay to extend anyone else's checkmark's expiration date!

    uint duration = numDays * (1 days);
    if(isExpired(tokenId)) {
      tokenExpirationDates[tokenId] = block.timestamp + duration;
    } else {
      tokenExpirationDates[tokenId] = tokenExpirationDates[tokenId] + duration;
    }
  }

  function isExpired(uint tokenId) public view returns (bool) {
    if(!_exists(tokenId)) revert NonexistentToken();
    return tokenExpirationDates[tokenId] < block.timestamp;
  }

  function burn(uint[] memory tokenIds) external {
    for(uint i = 0; i < tokenIds.length; i++) {
      if(!isExpired(tokenIds[i])) revert TokenNotExpired();
      _burn(tokenIds[i]);
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if(tokenId > totalMinted()) revert NonexistentToken();
    string memory svg;
    if(!_exists(tokenId)) {
      svg = string(
        abi.encodePacked(
          'data:image/svg+xml;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '<svg viewBox="0 0 512 512" width="512" height="512" xmlns="http://www.w3.org/2000/svg"><g transform="translate(256, 256) scale(0.05) translate(-256, -256)"><path style="fill:#FFB446;" d="M97.103,353.103C97.103,440.86,168.244,512,256,512l0,0c87.756,0,158.897-71.14,158.897-158.897c0-88.276-44.138-158.897-14.524-220.69c0,0-47.27,8.828-73.752,79.448c0,0-88.276-88.276-51.394-211.862c0,0-89.847,35.31-80.451,150.069c8.058,98.406-9.396,114.759-9.396,114.759c0-79.448-62.115-114.759-62.115-114.759C141.241,247.172,97.103,273.655,97.103,353.103z"/><path style="fill:#FFDC64;" d="M370.696,390.734c0,66.093-51.033,122.516-117.114,121.241c-62.188-1.198-108.457-48.514-103.512-110.321c2.207-27.586,23.172-72.276,57.379-117.517l22.805,13.793C229.517,242.023,256,167.724,256,167.724C273.396,246.007,370.696,266.298,370.696,390.734z"/><path style="fill:#FFFFFF;" d="M211.862,335.448c-8.828,52.966-26.483,72.249-26.483,105.931C185.379,476.69,216.998,512,256,512l0,0c39.284,0,70.729-32.097,70.62-71.381c-0.295-105.508-61.792-158.136-61.792-158.136c8.828,52.966-17.655,79.448-17.655,79.448C236.141,345.385,211.862,335.448,211.862,335.448z"/></g></svg>'
              )
            )
          )
        )
      );
    } else {
      uint scale = isExpired(tokenId) ? 1 : ((tokenExpirationDates[tokenId] - block.timestamp) / (24 * 60 * 60)) + 1;
      string memory hexColor = "#1da1f2";
      if(tokenColors[tokenId] == Colors.GRAY) {
        hexColor = "#7f7f7f";
      } else if(tokenColors[tokenId] == Colors.GOLD) {
        hexColor = "#dcab00";
      }
      svg = string(
        abi.encodePacked(
          'data:image/svg+xml;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '<svg viewBox="0 0 600 600" width="600" height="600" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="white"/><g transform="translate(300, 300) scale(', scale.toString(), ')"><path transform="scale(0.0025) translate(-256, -256)" d="m512 268c0 17.9-4.3 34.5-12.9 49.7s-20.1 27.1-34.6 35.4c.4 2.7.6 6.9.6 12.6 0 27.1-9.1 50.1-27.1 69.1-18.1 19.1-39.9 28.6-65.4 28.6-11.4 0-22.3-2.1-32.6-6.3-8 16.4-19.5 29.6-34.6 39.7-15 10.2-31.5 15.2-49.4 15.2-18.3 0-34.9-4.9-49.7-14.9-14.9-9.9-26.3-23.2-34.3-40-10.3 4.2-21.1 6.3-32.6 6.3-25.5 0-47.4-9.5-65.7-28.6-18.3-19-27.4-42.1-27.4-69.1 0-3 .4-7.2 1.1-12.6-14.5-8.4-26-20.2-34.6-35.4-8.5-15.2-12.8-31.8-12.8-49.7 0-19 4.8-36.5 14.3-52.3s22.3-27.5 38.3-35.1c-4.2-11.4-6.3-22.9-6.3-34.3 0-27 9.1-50.1 27.4-69.1s40.2-28.6 65.7-28.6c11.4 0 22.3 2.1 32.6 6.3 8-16.4 19.5-29.6 34.6-39.7 15-10.1 31.5-15.2 49.4-15.2s34.4 5.1 49.4 15.1c15 10.1 26.6 23.3 34.6 39.7 10.3-4.2 21.1-6.3 32.6-6.3 25.5 0 47.3 9.5 65.4 28.6s27.1 42.1 27.1 69.1c0 12.6-1.9 24-5.7 34.3 16 7.6 28.8 19.3 38.3 35.1 9.5 15.9 14.3 33.4 14.3 52.4zm-266.9 77.1 105.7-158.3c2.7-4.2 3.5-8.8 2.6-13.7-1-4.9-3.5-8.8-7.7-11.4-4.2-2.7-8.8-3.6-13.7-2.9-5 .8-9 3.2-12 7.4l-93.1 140-42.9-42.8c-3.8-3.8-8.2-5.6-13.1-5.4-5 .2-9.3 2-13.1 5.4-3.4 3.4-5.1 7.7-5.1 12.9 0 5.1 1.7 9.4 5.1 12.9l58.9 58.9 2.9 2.3c3.4 2.3 6.9 3.4 10.3 3.4 6.7-.1 11.8-2.9 15.2-8.7z" fill="', hexColor ,'"/></g></svg>'
              )
            )
          )
        )
      );
    }
    return (
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{',
                  '"name":"Blue Checkmark #', tokenId.toString(), '",',
                  '"description":"Blue Checkmarks are a subscription NFT. Subscription fees go to Coin Center.",',
                  '"image_data":"', svg, '",',
                  '"attributes": [',
                    '{',
                      '"trait_type": "Color",',
                      '"value": "', tokenColors[tokenId] == Colors.GOLD ? "Gold" : tokenColors[tokenId] == Colors.GRAY ? "Gray" : "Blue", '"',
                    '},',
                    '{',
                      '"trait_type": "Is from claim",',
                      '"value": "', tokensFromClaims[tokenId] ? "Yes" : "No" ,'"',
                    '},',
                    '{',
                      '"trait_type": "Is expired",',
                      '"value": "', !_exists(tokenId) || isExpired(tokenId) ? "Yes" : "No" ,'"',
                    '},',
                    '{',
                      '"trait_type": "Is burned",',
                      '"value": "', !_exists(tokenId) ? "Yes" : "No" ,'"',
                    '},',
                    '{',
                      '"display_type": "date",', 
                      '"trait_type": "Expiration date",',
                      '"value": ', tokenExpirationDates[tokenId].toString(),
                    '}',
                  ']',
                '}'
              )
            )
          )
        )
      )
    );
  }

  function donateBalance() public payable {
    amountDonated += address(this).balance;
    (bool os, ) = payable(recipient).call{value: address(this).balance}("");
    require(os);
  }

  // Let's hope no horror novelists make any threats...

  mapping(address => bool) public horrorNovelists;
  address public negotiatooor;
  bool gotThanked;

  function writeHorrorNovels() external {
    horrorNovelists[msg.sender] = true;
  }

  function threatenToBeGoneLikeEnron() external returns (string memory) {
    if(!horrorNovelists[msg.sender]) revert NotHorrorNovelist();
    if(negotiatooor != address(0x0)) revert NegotiationsConcluded();
    // ($8 @ $1700 ETH/USD) / 30 days per month = 0.0001567 ETH per day
    pricePerDay = 0.0001567 ether;
    negotiatooor = msg.sender;
    return "How about $8?";
  }

  function getThankYouFromEntireSocialMediaNetwork(address collection, uint tokenId) external {
    if(msg.sender != negotiatooor) revert NotAMasterNegotiatooor();
    if(gotThanked) revert AlreadyGotThanked();
    gotThanked = true;
    IERC721(collection).transferFrom(address(this), msg.sender, tokenId);
  }

  // Allow contract to receive direct ether donations
  receive() external payable {}
  fallback() external payable {}
}