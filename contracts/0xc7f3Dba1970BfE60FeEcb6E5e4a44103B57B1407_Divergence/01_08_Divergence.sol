//                      ▄▄▄                                             
//                   ▄▓▒▒▒▒▌                                            
//                ▄▓▒▒▒▒▒▒▀   ▄▄▒▒▒                                     
//             ▄▓▒▒▒▒▒▀    ▄▒▒▒▒▒▒▒         ▄▄▄▒▒▒▒                     
//          ▄▓▒▒▒▒▒▀   ▄▄▓▒▒▒▒▒▒▀▀   ▄▄▄▒▒▒▒▒▒▒▒▒▒▒▌                    
//        ▐▒▒▒▒▒▒   ▄▒▒▒▒▒▒▒▀   ▄▒▒▒▒▒▒▒▒▒▒▒▒▀▀▀▀                       
//         ▀▀▒▀   ▄▒▒▒▒▒▒▀  ▄▒▓▒▒▒▒▒▒▀▀▀                                
//                ▀▒▒▒▒  ▄▒▒▒▒▒▒▀▀                                      
//                     ▄▓▒▒▒▒▀                                          
//                    ▒▒▒▒▒▀                                            
//                  ▄▒▒▒▒▀    ▄▄▄▄                                      
//                 ▒▒▒▒▒    ▐▒▒▒▒▒▒▒                                    
//               ▄▒▒▒▒▒     ▓▒▒▒▒▒▒▒                                    
//             ▄▓▒▒▒▒▀       ▀▒▒▒▒▀                                     
//            ▐▒▒▒▒▒                          ▄▄▒▒▒▒▒▒▒▒▄               
//             ▀▒▒▀                       ▄▒▓▒▒▒▒▒▒▒▒▒▒▒▀               
//                                     ▄▒▒▒▒▒▒▀▀                        
//                                   ▄▓▒▒▒▒▀                            
//                ▄▒▒▒▒▄           ▄▒▒▒▒▒                               
//              ▄▒▒▒▒▒▒          ▄▓▒▒▒▒                                 
//             ▒▒▒▒▒▒          ▄▒▒▒▒▒▀                                  
//             ▒▒▒▒▀         ▄▒▒▒▒▒▀                                    
//                         ▄▓▒▒▒▒▀                                      
//                        ▐▒▒▒▒▒                                        
//          _ _             ▀▀                                          
//       __| (_)_   _____ _ __ __ _  ___ _ __   ___ ___ 
//      / _` | \ \ / / _ \ '__/ _` |/ _ \ '_ \ / __/ _ \
//     | (_| | |\ V /  __/ | | (_| |  __/ | | | (_|  __/
//      \__,_|_| \_/ \___|_|  \__, |\___|_| |_|\___\___|
//                            |___/  ʙʏ ʙᴜᴢᴢʏʙᴇᴇ
//
//               SPDX-License-Identifier: MIT
//           ɪɴsᴘɪʀᴀᴛɪᴏɴ ғʀᴏᴍ ᴅᴏᴏᴅʟᴇs ɢᴇɴᴇsɪs ʙᴏx
//            ᴀɴᴅ ʙᴜᴇɴᴏ.ᴀʀᴛ's ᴡᴏɴᴅᴇʀᴘᴀʟs ᴄᴏɴᴛʀᴀᴄᴛ

pragma solidity ^0.8.7;

// erc 721a is imported from its own npm
// module, not an openzeppelin one.
import "erc721a/contracts/ERC721A.sol";

// ownable is standard tho
import "@openzeppelin/contracts/access/Ownable.sol";

// this is from the wonderpals contract, i love how
// they handle allowlist spots
import "./Ticketed.sol";

contract Divergence is ERC721A, Ownable, Ticketed {
    string public _baseTokenURI;

    bool public saleActive = false;
    bool public publicSaleActive = false;

    uint supply = 4884;

    // withdrawal addr
    address private buzz = 0x816ae721F90d9cd5190d0385E7224C6798DaD52B;

    // this helps us reference the bids later from
    // my off-chain code
    struct User {
        uint216 contribution; // cumulative sum of ETH bids
        uint32 tokensClaimed; // tracker for claimed tokens
        bool refundClaimed; // has user been refunded yet
    }
    mapping(address => User) public userData;

    // events are easier to find on the chain than transaction
    // results, so we want to send events for bids
    event Bid(address bidder, uint256 bidAmount, uint256 bidderTotal, uint256 bucketTotal);

    constructor(string memory baseURI) ERC721A("Divergence", "DIV") {
        _baseTokenURI = baseURI;
    }

    // helper function to store a bid
    function bid() internal {
        // get user's current bid total
        User storage bidder = userData[msg.sender];

        // bidder.contribution is uint216
        uint256 contribution_ = bidder.contribution;

        // does not overflow
        unchecked {
            contribution_ += msg.value;
        }

        // set the new value
        bidder.contribution = uint216(contribution_);

        // emit the event for the off chain system to find
        emit Bid(msg.sender, msg.value, contribution_, address(this).balance);
    }

    function mintAllowlist(
        uint quantity,
        bytes[] calldata signatures,
        uint256[] calldata spotIds
    )
        external
        payable
    {
        // series of basic checks
        require(saleActive, "Sale is not active");
        require(
            totalSupply() + quantity <= supply,
            "Mint would go past max supply"
        );

        // verify all of the allowlist spots. this will
        // revert the entire transaction if it fails.
        for (uint i = 0; i < signatures.length; i++) {
            _claimAllowlistSpot(signatures[i], spotIds[i]);
        }

        // add to the bids if needed
        if (msg.value > 0) bid();

        // mint all of the tokens!
        _mint(msg.sender, quantity);
    }

    function mintPublic(uint quantity)
        external
        payable
    {
        // series of basic checks
        require(saleActive, "Sale is not active");
        require(publicSaleActive, "Public sale is not active");
        require(
            totalSupply() + quantity <= supply,
            "Mint would go past max supply"
        );
        // lol this error message
        require(quantity < 5, "A bit greedy are we? Quantity over max");

        // same as last time
        if (msg.value > 0) bid();

        _mint(msg.sender, quantity);
    }

    // this is just for me to mint the 1/1s
    function devMint(address receiver, uint256 qty) external onlyOwner {
        _mint(receiver, qty);
    }

    // flag flips!
    function setSaleState(bool active) external onlyOwner {
        saleActive = active;
    }

    function setPublicSaleState(bool active) external onlyOwner {
        publicSaleActive = active;
    }

    // this sets which "spots" are claimable by the ticketing
    // slash allowlist system
    function setClaimGroups(uint256 num) external onlyOwner {
        _setClaimGroups(num);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // this lets me reduce supply if we don't mint out
    function setSupply(uint newSupply) external onlyOwner {
        require(newSupply < supply, "wow, bit greedy are we?");
        supply = newSupply;
    }

    // for some reason erc 721a's first token is id #0 by default
    // this override sets that to #1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // this tells the contract who is signing spots off-chain
    function setSigner(address _signer) external onlyOwner {
        _setClaimSigner(_signer);
    }

    // get my moneysss
    function withdraw() external onlyOwner {
        (bool s, ) = buzz.call{value: (address(this).balance)}("");
        require(s, "withdraw failed");
    }
}