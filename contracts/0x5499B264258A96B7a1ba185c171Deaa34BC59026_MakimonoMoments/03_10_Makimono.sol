// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

//                             .. .          ,
//                       %&((#/%&&(##%
//                     .,%. ##*#%%&&(%&/*               ,
//  &.                  .%..  .#%%(((#. %*#
//   &@*&                #.%/%(%/((((#%./
//     &&&@             .&%(//(#&%@%&%&&
//      &&&%.           %&#&((##%%&&@%.#
//     #.&&&&@@       %(#&((#&#/%&#*&#%#
//         &&&% &      @#&#(/(((@%((#&&#&%
//      /&@&&&@@@     %@((((&((@@&((&@%&&&&
//     @&@@&.&@&./#&#((#%%((&&@@&#(*#@(#(#@&%  ,
//       @@    &@&& &&@@@@@@&&@@//%%(&(/#%&%
//        @&   .&@@,[email protected]&&&#(#(((&@@@#%@&@&@@&&#
//          @ . [email protected]&&&*@(((&&(%((&@&@&&@@@@@###%###
//               ,.%% %(((((((%&@@@&#&###&%&#@&&###%
//          . .       @&&&&%##%@@@&@@%%#*######%####
//          .  .     @&/////(*.  @&  @@&%%%#######%%.
//             *     &%&((#/*    &%     @@@@&&###@&&
//                  . %%%#(//    % *       @@&&@&%%
//                  . %(%%%(/                 (@@@&
//                    &%#&@.%@*,                @.
//                        &&###(*/
//                         %#(%%@%&&%
//                    ,     #@%#.&&@@@,
//                          &&@&,,&&&&&&@@&      &.
//                          %@&&&,.,@@&&%.        %.
//                     ., ,%&%%&&/,,@&&@%  ..  .&&&
//          .,.  . .(.%####&%&&&&@@@@@@@@/[email protected]/.     @
//     @      .  @    @@@&&&@@&.&(@@@@@@@@@@  [email protected]@@@  .  @&@

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract MakimonoMoments is
    ERC721A("Makimono: Moments", "MOMENTS"),
    ERC721AQueryable,
    Ownable,
    DefaultOperatorFilterer
{
    enum State {
        PAUSED,
        PRESALE,
        PUBLIC
    }

    // ************************************************************************
    // * Constants
    // ************************************************************************

    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant MAX_MINT_PER_WALLET = 1;

    // ************************************************************************
    // * Storage
    // ************************************************************************

    uint256 public travelerFare = 0.009 ether;
    string public baseTokenURI;
    mapping(address => uint256) public freeClaimsRemaining;

    State public state;

    // ************************************************************************
    // * Function Modifiers
    // ************************************************************************

    modifier mintCompliance(uint256 amount) {
        require(msg.sender == tx.origin, unicode"🤖 🤡 🙅‍♀️, traveler");
        require(totalSupply() + amount <= MAX_SUPPLY, "The expanse is complete. You're too late, traveler");
        require(_numberMinted(msg.sender) + amount <= MAX_MINT_PER_WALLET, "Pack light, space is limited, traveler");
        _;
    }

    modifier priceCompliance(uint256 amount) {
        require(msg.value >= amount * travelerFare, "You lack the mana required, traveler");
        _;
    }

    // ************************************************************************
    // * View Functions
    // ************************************************************************
    function isWhitelisted(address account) public view returns (bool) {
        return _getAux(account) == 1;
    }

    // @note this function is already provided by the public state variable `freeClaimsRemaining`
    // function freeClaimsRemaining(address account) public view returns (uint256) {
    //     return freeClaimsRemaining[account];
    // }

    // ************************************************************************
    // * Mint Functions
    // ************************************************************************

    function twilightDusk(uint256 amount) external payable mintCompliance(amount) priceCompliance(amount) {
        require(state == State.PUBLIC, "Not too early, traveler");
        _mint(msg.sender, amount);
    }

    function earlyDawn(uint256 amount) external payable mintCompliance(amount) priceCompliance(amount) {
        require(state != State.PAUSED, "Not too early, traveler");
        require(isWhitelisted(msg.sender), "You aren't a chosen one, traveler");
        _mint(msg.sender, amount);
    }

    function claim() external {
        require(state != State.PAUSED, "Not too early, traveler");
        uint claimsRemaining = freeClaimsRemaining[msg.sender];
        require(claimsRemaining > 0, "You have zero claims remaining, traveler");
        uint supplyRemaining = MAX_SUPPLY - totalSupply();
        uint amountToMint = _minimum(claimsRemaining, supplyRemaining);
        freeClaimsRemaining[msg.sender] -= amountToMint;
        _mint(msg.sender, amountToMint);
    }

    // ************************************************************************
    // * Admin Functions
    // ************************************************************************

    function ownerMint(uint256 amount, address to) external onlyOwner {
        require(amount + totalSupply() <= MAX_SUPPLY, "No more travelers, Architecht");
        _safeMint(to, amount);
    }

    function addWhitelist(address[] calldata whitelist) external onlyOwner {
        for (uint256 i; i < whitelist.length; ) {
            _setAux(whitelist[i], 1);
            unchecked {
                i++;
            }
        }
    }

    function addFreeClaims(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i; i < addresses.length; ) {
            freeClaimsRemaining[addresses[i]] = amounts[i];
            unchecked {
                i++;
            }
        }
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function openPortal(State newState) external onlyOwner {
        state = newState;
    }

    function setTravelerFare(uint256 newPrice) external onlyOwner {
        travelerFare = newPrice;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "Mana withdrawal failed, Architecht");
    }

    // ************************************************************************
    // * Operator Filterer Overrides
    // ************************************************************************
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ************************************************************************
    // * Internal Overrides
    // ************************************************************************

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    // ************************************************************************
    // * Internal Helpers
    // ************************************************************************

    function _minimum(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}