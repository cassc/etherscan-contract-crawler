// SPDX-License-Identifier: CC-BY-NC-ND-4.0

/*


     @@@@@: @ @@@@ @@@@ @  @ @@@@ @  @  @@@@ @ [email protected] @@@   @@@ @@@@ @@@ @@@@[email protected]@@%@@@@ @  @ @@ *@
      @  @: @ @: @ @  @ @  @ @  @ @  @   [email protected]  @ [email protected] @    @@ @ @: @ @   @  @  @  @  @ @  @ @@ @@
      @  @: @ @: @ @  @ @  @ @    @  @   [email protected]  @ [email protected] @     @   @: @ @   @     @  @  @ @  @ @@ @@
      @  @@@@ @@@% @  @ @  @ @ @@ @@@@   [email protected]  @@@@ @@@    @@ @@@@ @@@ @     @  @@@. @  @ @@[email protected]@
      @  @: @ @:@= @  @ @  @ @  @ @  @   [email protected]  @ [email protected] @       @ @:   @   @  %  @  @ @  @  @ @ @@@
      @  @: @ @:[email protected] @  @ @  @ @  @ @  @   [email protected]  @ [email protected] @    @@ @[email protected]:   @   @  @  @  @ @@ @  @ @ @ @
      @  @: @ @: @ [email protected]@@ #@@+ @@@@ @  @   [email protected]  @ [email protected] @@@   @@@ @:   @@@ [email protected]@@  @  @  @ @@@: @ @ @


                         @  @  @ @ @   @   @@@  @@    @@@ @ %@ @ @@@:@  @
                         @% @ [email protected] @ @   @   @    @@      @ @ @@ @ @   @% @
                          @ @[email protected]  @ @   @   @    @@     @@ @ @@ @ @    @@+
                          @@ @@  @ @   @   @@@  @@@    @  @ @@ @ @@@  @@
                          @@ @@  @ @   @   @   #@ @   @@  *@@@[email protected] @    @@
                          @@ @@  @ @   @   @   @@@@   @    @@[email protected] @    #@
                          @@ @@  @ @%% @%% @%% @  @  @@%%  @  @  @%%: #@
                          .# ##  # ### ### ### #  #  ####  #  #  ###. +#




      @  %@        @.       *@  @    *@@@.                   @@%@    @%@@                   [email protected]@@=
         #.:%-   [email protected]@@@    @ =.       :  @. @     [email protected]@@     @.%.          .#:@     @@@:     @  @  =
     @    == = @  @@@+ %:% .*    @   %      %[email protected]  @@@@  [email protected]*  .   +    -   =  [email protected]  @@@@  @ #      #
      @       + %@@@@@- %       @     @%+    @ *@ [email protected] %  :.  %:%*      *%:%  .:..* @. @# @    *%@
        @@     [email protected]:@@@*%-     #@:       %     =% =%@@@% *#.  @ @        @ @  .#* %@@@*- %=    .*
            @@@%[email protected]@@@.%@@@.                 [email protected]@@@@@@@@@#                    #@@@@@@@@@@.
        @: -  =+ %@@@# .%     @          @ #=  %[email protected]@@@ %: :@ %+          +# %. :# @@@@:%  =* @
       @      % @ @@@ @ @      %       :*     - @ @@@@ @     [email protected]        @.  .  % @@@@ @ :     *
       .      @   %@@   @ @ :  @            * @   @@   %.  :  @        @  -  :#   @@   @ :
         @@@=      @      [email protected]@@           @@@+     %@      @#@            @#@      @*     *@@@
                   @                              [email protected]                              @.
                   @                              :@                              @.
                   @                              [email protected]                              @
                   @                               @                              @
                   @                               @                              @
                   @                               @                              @
                   @
                   @                               @                              @
                                                   @                              @
                   @                               :                              :
                   @                               @                              @




*/

pragma solidity ^0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// @author ianolson.eth
contract ThroughTheSpectrum is Ownable, ERC721 {
    using SafeMath for uint256;

    // ---
    // Supported Interfaces
    // ---

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_RARIBLE_ROYALTIES = 0xcad96cca; // bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca

    // ---
    // Events
    // ---

    event Mint(uint256 indexed tokenId, address indexed owner);

    // ---
    // Modifiers
    // ---

    modifier onlyAdmin {
        require(isAdmin[msg.sender], "Only Admins.");
        _;
    }

    modifier onlyActive {
        require(active, "Minting is not active");
        _;
    }

    modifier onlyNonPaused {
        require(!paused, "Minting is paused.");
        _;
    }

    // ---
    // Properties
    // ---

    uint256 public invocations = 0;
    uint256 public maxInvocations = 50;
    uint256 public nextTokenId = 1;
    uint256 public maxQuantityPerTransaction = 1;
    uint256 public royaltyFeeBps = 1000;
    bool public active = false;
    bool public paused = false;
    string public contractURI = "https://ipfs.imnotart.com/ipfs/Qma8z2v9kT1xLquHWi31rJ78EeSTmG6WsdxXqhmBiZfyWs";
    string public metadataBaseUri = "https://api.imnotart.com/";
    

    // ---
    // Mappings
    // ---

    mapping(address => bool) isAdmin;
    

    // ---
    // Constructor
    // ---

    // @dev Contract constructor.
    constructor() ERC721("Through the Spectrum", "THROUGHTHESPECTRUM") {

        // Add default admins.
        isAdmin[msg.sender] = true; // Deployer account.
        isAdmin[address(0x900C0c2FD84f7385ae36421499c7b3E99c8E058a)] = true; // imnotArt Admin Address
        isAdmin[address(0xB802162900a4e2d1b2472B14895D56A73aE647E8)] = true; // Artist Admin Address

        // Set the Metadata Base URI for imnotArt API
        metadataBaseUri = string.concat(metadataBaseUri, string.concat(Strings.toHexString(address(this)), "/"));
    }

    // ---
    // Supported Interfaces
    // ---

    // @dev Return the support interfaces of this contract.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165
        || interfaceId == _INTERFACE_RARIBLE_ROYALTIES
        || interfaceId == _INTERFACE_ID_ERC721
        || interfaceId == _INTERFACE_ID_ERC721_METADATA
        || interfaceId == _INTERFACE_ID_EIP2981
        || super.supportsInterface(interfaceId);
    }

    // ---
    // Minting
    // ---

    // @dev Mint to function for admins to mint to a specific address.
    function mintTo(address toAddress, uint256 quantity) external onlyActive onlyNonPaused onlyAdmin {
        require(quantity <= maxQuantityPerTransaction, StringsUtil.concat("Max limit per transaction is ", StringsUtil.uint2str(maxQuantityPerTransaction)));
        require(invocations.add(quantity) <= maxInvocations, "Must not exceed max invocations.");

        internalMint(toAddress, quantity);
    }

    // @dev Internal mint function.
    function internalMint(address to, uint256 quantity) internal {
        uint8 index;
        uint256 tokenId = nextTokenId;
        for (index = 0; index < quantity; index++) {
            _safeMint(to, tokenId);
            emit Mint(tokenId, to);
            tokenId = tokenId.add(1);
        }

        // Update the nextTokenId property.
        nextTokenId = nextTokenId.add(quantity);

        // Update number of invocations.
        invocations = invocations.add(quantity);
    }

    // ---
    // Functions
    // ---

    // @dev Override the tokenURI function to return the base URL + concat and tokenId.
    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "Token ID does not exist.");
        return StringsUtil.concat(metadataBaseUri, StringsUtil.uint2str(tokenId));
    }

    // @dev Total supply of tokens that are currently minted.
    function totalSupply() external view returns (uint256) {
        return invocations;
    }

    // ---
    // Admin Functions
    // ---

    // @dev Add an address to the isAdmin mapping.
    function addAdmin(address addressToAdd) external onlyAdmin {
        isAdmin[addressToAdd] = true;
    }

    // @dev Remove an address from the isAdmin mapping.
    function removeAdmin(address addressToRemove) external onlyAdmin {
        isAdmin[addressToRemove] = false;
    }

    // @dev Update the contract uri.
    function updateContractUri(string memory newContractUri) external onlyAdmin {
        contractURI = newContractUri;
    }

    // @dev Update the base URL that will be used for the tokenURI() function.
    function updateMetadataBaseUri(string memory _metadataBaseUri) external onlyAdmin {
        metadataBaseUri = _metadataBaseUri;
    }

    // @dev Update the max invocations, this can only be done BEFORE the minting is active.
    function updateMaxInvocations(uint256 newMaxInvocations) external onlyAdmin {
        require(!active, "Cannot change max invocations after active.");
        maxInvocations = newMaxInvocations;
    }

    // @dev Update the max quantity per transaction, this can only be done BEFORE the minting is active.
    function updateMaxQuantityPerTransaction(uint256 newMaxQuantityPerTransaction) public onlyAdmin {
        require(!active, "Cannot change max quantity per transaction after active.");
        maxQuantityPerTransaction = newMaxQuantityPerTransaction;
    }

    // @dev Enable minting and make contract active.
    function enableMinting() external onlyAdmin {
        active = true;
    }

    // @dev Toggle the pause state of minting.
    function toggleMintPause() external onlyAdmin {
        paused = !paused;
    }

    // @dev Take the balance of the given contract and transfer it to the caller.
    function withdraw() external onlyAdmin {
        uint256 amount = address(this).balance;
        require(amount > 0, "Contract balance empty.");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    // ---
    // Royalties
    // ---

    // @dev Rarible royalties V2 implementation.
    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory) {
        require(_exists(id), "Token ID does not exist.");

        LibPart.Part[] memory royalties = new LibPart.Part[](1);
        royalties[0] = LibPart.Part({
            account : payable(address(this)),
            value : uint96(royaltyFeeBps)
        });

        return royalties;
    }

    // @dev EIP-2981 royalty standard implementation.
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 amount) {
        require(_exists(tokenId), "Token ID does not exist.");

        uint256 royaltyPercentageAmount = SafeMath.div(SafeMath.mul(salePrice, royaltyFeeBps), 10000);
        return (payable(address(this)), royaltyPercentageAmount);
    }
}

library StringsUtil {

    function concat(string memory _base, string memory _value) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    function address2str(address _address) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(_address)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 length;

        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;

        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }

        str = string(bstr);
    }
}

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}