// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//
//
//
//	       #    #    ##    #####    ####       #    #    ##    #  ######  #####    ####
//	       ##  ##   #  #   #    #  #           ##  ##   #  #   #  #       #    #  #
//	       # ## #  #    #  #    #   ####       # ## #  #    #  #  #####   #    #   ####
//	       #    #  ######  #####        #      #    #  ######  #  #       #####        #
//	       #    #  #    #  #   #   #    #      #    #  #    #  #  #       #   #   #    #
//	       #    #  #    #  #    #   ####       #    #  #    #  #  ######  #    #   ####
//
//
//
//                      .......                                    .......
//                .**'''        '''**,                       ***'''        '''**
//             **,.                   ,**                .**,                   .**,
//           /*,..                     ..**.           ,**..                     ..,**
//         **,......%##%... ....(###*.....,*/        ./*......(###*. . ....%##%......**,
//        /*,,,.....##(/........*(##,....,,,*/      ./*,,,....*#((,........((##.....,,,**
//       //*,,,,,,,..................,,,,,,,**/     /**,,,,,,,.................,,,,,,,,*/,
//       /****,,,,,,,,,,,,(..*,,,,,,,,,,,,,***/.   */***,,,,,,,,,,,,*,.,,,,,,,,,,,,,,***//
//       //***,,,,,,,,,,,%(..#%*,,,,,,,,,,****/,   */****,,,,,,,,,,/%,.,%#,,,,,,,,,,,***/(
//       (/****,,,,,,,,,,*/..*,,,,,,,,,,,****/(    ,//****,,,,,,,,,,(,.*,,,,,,,,,,,*****//
//       ,(/*****,,,,,,,**,,,.,,/,,,,,,*****///     ///****,,,,,,,,*,,,.,,*,,,,,,,*****/(.
//        *(/******,,,*/,.....*************///       (//******,,,(,.....,,*/***,*****//(.
//         .(//*******/,..,(,,****.*#****//(,         *(//******(,..,**,,///,,(/****//(
//           .(///***(,..,,(**/#,,%/**///(*             /(//***//,..,*/,/((,/#***///(
//              *(//(/,,,,,*(#*,/%(///(/                  .((//#*,,,,*/((**%#////(,
//                  *(,,,,,**/(%%#(*                           (*,,,,**/*%%%#(.
//                    /***/*                                    ,***//.
//
//
//                                          #####  #   #
//                                          #    #  # #
//                                          #####    #
//                                          #    #   #
//                                          #    #   #
//                                          #####    #
//
//                 #                                ######
//                 #   ##    ####   ####  #####     #     # #      #   ##   #    # #
//                 #  #  #  #    # #    # #    #    #     # #      #  #  #  ##   # #
//                 # #    # #      #    # #####     ######  #      # #    # # #  # #
//           #     # ###### #      #    # #    #    #     # # #    # ###### #  # # #
//           #     # #    # #    # #    # #    #    #     # # #    # #    # #   ## #
//            #####  #    #  ####   ####  #####     ######  #  ####  #    # #    # #
//
//                       #                                   #     #
//                      # #   #      #        ##   #    #     #   #  #    #
//                     #   #  #      #       #  #  ##   #      # #   #    #
//                    #     # #      #      #    # # #  #       #    #    #
//                    ####### #      #      ###### #  # #       #    #    #
//                    #     # #      #      #    # #   ##       #    #    #
//                    #     # ###### ###### #    # #    #       #     ####
//
//
//

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/// @custom:security-contact [email protected]
contract MarsMaiers is ERC721, AccessControl, ReentrancyGuard {
  using Address for address payable;
  using ECDSA for bytes32;

  /// can create refund approvals
  bytes32 public constant RECEIPT_SIGNER_ROLE = keccak256('RECEIPT_SIGNER_ROLE');

  /// can settle auctions
  bytes32 public constant SETTLER_ROLE = keccak256('SETTLER_ROLE');

  /// can withdraw winnings, and manage baseURI
  bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

  uint256 private constant MIN_BID = 0.01 ether;

  string private baseURI = 'https://marsmaiers.com/tokenURI/';
  bool private baseURILocked = false;

  /// tracks withdrawable winnings
  uint256 private winnings;

  /// tracks cumulative total of bid tokens
  mapping(string => uint256) private bids;

  /// tracks addresses that control bids
  mapping(string => address) private bidders;

  // tracks if entire project has been minted
  bool private projectConcluded = false;

  // used to keep offchain store synchronized
  event BidPlaced(string bidToken, address bidder, uint256 value, uint256 total);
  event Refunded(string bidToken, address bidder, uint256 total);

  constructor() ERC721('Mars Maiers', 'MARS') {
    // grant deployer DEFAULT_ADMIN_ROLE and MANAGER_ROLE
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MANAGER_ROLE, msg.sender);
  }

  /// @notice allows changing baseURI to IPFS, after project is concluded
  /// @param uri new baseURI value
  /// @param lock passing "true" will freeze current baseURI value and block any future changes
  function setBaseURI(string memory uri, bool lock) external onlyRole(MANAGER_ROLE) {
    require(!baseURILocked, 'baseURI is locked');

    baseURI = uri;

    if (lock) {
      baseURILocked = true;
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /** requires an encrypted bidToken (generated on marsmaiers.com)

  ======================================
  == DO NOT CALL THIS METHOD DIRECTLY ==
  ======================================

  if you call this method directly (through etherscan or by hand), your bid
  will NOT be counted. your funds will be unrefundable, and you will have to
  wait for the project to be concluded, once refund() is available

  ======================================
  ==                                  ==
  ==    ONLY BID ON MARSMAIERS.COM    ==
  ==                                  ==
  ======================================
  **/
  function bid(string calldata bidToken) public payable {
    // validate input
    bytes memory bidTokenCheck = bytes(bidToken);
    require(bidTokenCheck.length > 0, 'invalid input');

    // ensure project is still ongoing
    require(!projectConcluded, 'project has concluded');

    // ensure bid meets min
    require(msg.value >= MIN_BID, 'below min bid');

    // if bidToken is already set, ensure _msgSender is the original bidder
    require(bidders[bidToken] == address(0x0) || bidders[bidToken] == _msgSender(), 'not your bid');

    // increment bidToken to new cumulative total
    bids[bidToken] = bids[bidToken] + msg.value;

    // mark _msgSender as bidder
    bidders[bidToken] = _msgSender();

    // emit event
    emit BidPlaced(bidToken, msg.sender, msg.value, bids[bidToken]);
  }

  /// returns bidder and bid total for a given bid token
  function getBidToken(string memory bidToken) public view returns (uint256, address) {
    return (bids[bidToken], bidders[bidToken]);
  }

  /// returns withdrawable winnings
  function getWinnings() public view returns (uint256) {
    return winnings;
  }

  /// @notice chooses a winner, and moves value ofbidToken to winnings
  /// @param tokenId day of year to mint
  /// @param bidToken winning bid token
  function settle(uint256 tokenId, string memory bidToken) public onlyRole(SETTLER_ROLE) {
    // validate input
    bytes memory bidTokenCheck = bytes(bidToken);
    require(tokenId >= 1 && tokenId <= 365 && bidTokenCheck.length > 0, 'invalid input');

    // no more winners allowed
    require(!projectConcluded, 'project has concluded');

    // look up bid total and winner by bidToken
    address winner = bidders[bidToken];
    uint256 amount = bids[bidToken];

    // ensure bidToken is not zero
    require(winner != address(0x0) && amount > 0, 'unknown bidToken');

    // zero bid
    bids[bidToken] = 0;

    // add amount to winnings
    winnings = winnings + amount;

    // close it up after final mint
    if (tokenId == 365) {
      projectConcluded = true;
    }

    // mint NFT to winner
    _safeMint(winner, tokenId);
  }

  /// @notice allows owner to cash out, from the designated winnings only
  /// @param amount value in wei to transfer
  /// @param to address to transfer funds to
  function withdraw(uint256 amount, address to) external onlyRole(MANAGER_ROLE) {
    require(amount > 0, 'invalid input');
    require(amount <= winnings, 'amount exceeds winnings');

    // subtract amount
    winnings = winnings - amount;

    // send funds to destination
    payable(to).sendValue(amount);
  }

  /// @notice transfers funds for a lost bid back to original bidder. requires a signed signature generated on marsmaiers.com
  /// @param bidToken bid token representing the lost bid you are refunding
  /// @param nonce nonce string, generated along with signature
  /// @param signature signature containing bidToken and nonce. generated on marsmaiers.com
  function signedRefund(
    string memory bidToken,
    string memory nonce,
    bytes memory signature
  ) public nonReentrant {
    // infer message by hashing input params. signature must contain a hash with the same message
    bytes32 message = keccak256(abi.encode(bidToken, nonce));

    // validate inferred message matches input params, and was signed by an address with RECEIPT_SIGNER_ROLE
    // if this passes we can trust the input params match
    require(hasRole(RECEIPT_SIGNER_ROLE, message.toEthSignedMessageHash().recover(signature)), 'invalid receipt');

    // execute refund
    _refund(bidToken);
  }

  /// @notice generic mechanism to return the value of a list of bidTokens to their original bidder. only enabled once project has concluded.
  /// @param bidTokens array of bid tokens to refund
  function refund(string[] memory bidTokens) public nonReentrant {
    // only allow unsigned refunds once project is concluded
    require(projectConcluded, 'project has not concluded');

    // execute refund for each bidToken
    for (uint256 i = 0; i < bidTokens.length; i++) {
      _refund(bidTokens[i]);
    }
  }

  /// allows *anyone* to mark the project as concluded, if the entire year has elapsed.
  /// this should normally never be needed, as minting the final piece also marks
  /// the project as concluded. in the unlikely event the final piece is never minted,
  /// this gives the community a way to release all pending bids.
  function concludeProject() public {
    // require block time to be after January 2, 2023 1:00:00 AM GMT (one day of buffer)
    require(block.timestamp > 1672621200, 'year is not over');

    // mark project as concluded
    projectConcluded = true;
  }

  // === PRIVATE ===

  // internal method to validate and process return a bid, using bidder and amount keyed to bidToken
  function _refund(string memory bidToken) private {
    // ensure bidToken exists with a balance, and was placed by _msgSender
    require(bids[bidToken] > 0, 'bid does not exist');

    // stash and zero bid
    uint256 amount = bids[bidToken];
    bids[bidToken] = 0;

    // don't zero bidder (prevents future reuse of bidToken)
    address bidder = bidders[bidToken];

    // emit event
    emit Refunded(bidToken, bidder, amount);

    // issue refund to bidder
    payable(bidder).sendValue(amount);
  }

  // === REQUIRED OVERRIDES ===

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}