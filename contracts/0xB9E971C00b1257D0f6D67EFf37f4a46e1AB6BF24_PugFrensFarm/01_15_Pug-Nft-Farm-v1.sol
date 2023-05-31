pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';


//
//          ██████╗ ██╗   ██╗ ██████╗ ███████╗██████╗ ███████╗███╗   ██╗███████╗
//          ██╔══██╗██║   ██║██╔════╝ ██╔════╝██╔══██╗██╔════╝████╗  ██║██╔════╝
//          ██████╔╝██║   ██║██║  ███╗█████╗  ██████╔╝█████╗  ██╔██╗ ██║███████╗
//          ██╔═══╝ ██║   ██║██║   ██║██╔══╝  ██╔══██╗██╔══╝  ██║╚██╗██║╚════██║
//          ██║     ╚██████╔╝╚██████╔╝██║     ██║  ██║███████╗██║ ╚████║███████║
//          ╚═╝      ╚═════╝  ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚══════╝
//
//                                     *
//                      *        *&&&&@@@@@@@@@@@
//                     */////  &&&&&&&&&&&&&&&&&@@@@@  ///
//                   **/////// %&&&&&&&&&&&&&&&&&&&&@@@@  */
//                 ***//////// ,%&&&&&&&&&&&&&&&&&&&&&&&@@  */
//                ***///////// %%&&&&&&&&&&&&&&&&&&&&&&&&&@@ */
//               ****//////// ,%&&&&&&&&&&&&&&&&&&&&&&&&&&&&& */ *
//              *****////////  *///////  &&&&&&&&&&&  /////  , */
//             ,*****/////// **//    ////  &&&&&&&& ////   //  *//
//              *****////// **/  @@.   *// (&&&&&&& // @@    / **//
//               *****//// **//      @  //    ////  */     @ / **//
//                 ****//  *////   @     // ,/ /*/  /  /   /// **.
//                   **  %% /////////  /////*******///// ////*
//                 %%%%%%%%&&&    .   /////***   ***//// *&&&&
//                  %%%%%%%&&&&&&&&&&%       %&&&%      &&&&&%
//                    %%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
//                        %%%%%&&&&&&&&&&&&&&&&&&&&&&&&&
//                       %%%&.&/      &&&&&&&&&&&&&##&&&&&
//                       %%  &&&&&&&&&&&&&&&&&&&&&&&&&&&&& *
//                       %  @&&&&&&%&&&&&&&&&&&&&&&&&&&&&& @@
//                      %% @&&&&&%% &&&&&&&&&&&&&&&&&&&&&& &@
//                      %/ @&&&&%% &&&&&&&&&&&&&&&&&&&&&&@ &&@
//                      %# @&&&%% &&&&&&&&&&&&&&&&&&&&&&&@ &@ *
//                      %% *@&%  &&&&&&&&&&&&&&&&&&&&&&&&*
//
//
//  Find out more on nft.pug.cash
//

contract PugFrensFarm is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    bool public _isSaleActive = false;
    bool public _isFriendSaleActive = false;
    string private _baseURIExtended;
    uint256 public maxMintablePerCall = 10;
    address[] public friendCommunities;
    uint256 public freePugFrensAvailable = 0;

    // Constants
    uint256 public constant MAX_SUPPLY = 8787;
    uint256 public NFT_PRICE = .04 ether;
    uint256 public MAX_NFT_PER_COMMUNITY_FRIEND = 1;

    event FriendSaleStarted();
    event FriendSaleStopped();
    event SaleStarted();
    event SaleStopped();
    event TokenMinted(uint256 supply);

    constructor() ERC721('PugFrens', 'PUG') {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function getPugsByOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _baseMint (uint256 num_tokens, address to) internal {
        require(totalSupply().add(num_tokens) <= MAX_SUPPLY, 'Sale would exceed max supply');
        uint256 supply = totalSupply();
        for (uint i=0; i < num_tokens; i++) {
            _safeMint(to, supply + i);
        }
        emit TokenMinted(totalSupply());
    }

    function mint(address _to, uint _count) public payable {
        require(_isSaleActive, 'Sale must be active to mint PugFrens');
        require(NFT_PRICE*_count <= msg.value, 'Not enough ether sent (check NFT_PRICE for current token price)');
        require(_count <= maxMintablePerCall, 'Exceeding max mintable limit for contract call');
        _baseMint(_count, _to);
    }

    function friendMint(address _friendCollection) external {
        require(_isFriendSaleActive, 'FriendSale must be active to mint PugFrens');
        
        // require that max number of PugFrens mintable for free has not been already reached
        require(freePugFrensAvailable >= 1, "Reached max number of free PugFrens mintable");

        // required that _friendCollection is in friendCommunities
        require(isAddressAFriendCommunity(_friendCollection), 'friendCollection needs to be in friend community');

        // required that sender has no more than MAX_NFT_PER_COMMUNITY_FRIEND NFTs
        require( this.balanceOf(msg.sender) < MAX_NFT_PER_COMMUNITY_FRIEND, "Max PugFrens mintable for free reached" );

        // require that sender has at least 1 NFT in friendCommunity
        IERC721 friendContract = IERC721(_friendCollection);
        uint256 balance = friendContract.balanceOf(msg.sender);
        require(balance>=1, "Need to own at least one token from given collection");
        
        _baseMint(1, msg.sender);
        freePugFrensAvailable = freePugFrensAvailable - 1;
    }

    function isAddressAFriendCommunity(address c) public view returns (bool) {
        bool isFriend = false;
        for (uint i=0; i<friendCommunities.length; i++) {
            if (c == friendCommunities[i]) {
                isFriend = true;
                break;
            }
        }
        return isFriend;
    }

    function ownerMint(address[] memory recipients, uint256[] memory amount) external onlyOwner {
        require(recipients.length == amount.length, 'Arrays needs to be of equal lenght');
        uint256 totalToMint = 0;
        for (uint256 i=0; i<amount.length; i++) {
            totalToMint = totalToMint + amount[i];
        }
        require(totalSupply().add(totalToMint) <= MAX_SUPPLY, 'Mint will exceed total supply');

        for (uint256 i=0; i<recipients.length; i++) {
            _baseMint(amount[i], recipients[i]);
        }
    }

    function pauseSale() external onlyOwner {
        _isSaleActive = false;
        emit SaleStopped();
    }

    function pauseFriendSale() external onlyOwner {
        _isFriendSaleActive = false;
        emit FriendSaleStopped();
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setMaxMintablePerCall(uint256 newMax) external onlyOwner {
        maxMintablePerCall = newMax;
    }

    function setMaxNFtPerCommunityFriend(uint256 newMax) external onlyOwner {
        MAX_NFT_PER_COMMUNITY_FRIEND = newMax;
    }

    function setPrice(uint256 price) external onlyOwner {
        NFT_PRICE = price;
    }

    function setFreePugFrensAvailable(uint256 available) external onlyOwner {
    freePugFrensAvailable = available;
    }

    function setFriendCommunities (address[] memory collections) external onlyOwner {
        delete friendCommunities;
        friendCommunities = collections;
    }

    function startSale() external onlyOwner {
        _isSaleActive = true;
        emit SaleStarted();
    }
    
    function startFriendSale() external onlyOwner {
        _isFriendSaleActive = true;
        emit FriendSaleStarted();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}