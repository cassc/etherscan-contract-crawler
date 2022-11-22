// SPDX-License-Identifier: MIT

/// @title State Of The Art by ThankYouX
/// @author transientlabs.xyz

/*                                                                                                                                                                                                                                                               
                   ."<}|\|[!^    .!!!!!!!!!!!!!!!!!l       '!!!'      "!!!!!!!!!!!!!!!!!' !!!!!!!!!!!!!!.               `:_1|\([i^.        `!!!!!!!!!!!!"        ,!!!!!!!!!!!!!!!!!` ^!!!!.         I!!!I     ^!!!!!!!!!!!!^                 '!!!`          .!!!!!!!!!I:^.      !!!!!!!!!!!!!!!!!!          
                 ,x$$Wr|)/z$$&!  `[email protected]$$&vccccv(       f$$$]      /vccccc&$$Bvcccccv''$$$$$$$$$$$$$$.            '?&$$zt||[email protected]      /$$8nnnnnnnnn;        &$$$$$$$$$$$$$$$$$, j$$$$.        .$$$$n     f$$&vcccccccv:                 v$$$f          :$$$unnnnuzB$$#>.  'vvccccz$$$Mcccccv/          
                \$${'      'j$$|         B$$:             :$$B$z             )$$\        ,$$$$r"""""""""            :@$W,.      .)$$M'     %$$_                  """"""{$$$$|"""""". B$$$#         "$$$$[     &$$I                          I$$B$B          {$$#        `|$$#.        '$$$`                 
               -$$?         .B$$.       `$$$`            .%$|)$$.            z$$+        ~$$$$!                    `@$$'          *$${    '$$$"                        [$$$$,       `$$$$/         -$$$$;    .$$$^                         .&$u1$$'         *$$)          &$$,        ,[email protected]                  
               W$$`          n$$`       I$$$.            j$%.l$$"            @$$,        |$$$$`                    z$$[           |$$r    ;$$$.                        x$$$$.       I$$$$+         u$$$$^    ,$$$.                         {[email protected]'i$$"        .$$$;          c$$I        ~$$z                  
               u$$|          `'.        |$$v            ,$$> `$$-           `$$$'        #$$$B                    ^$$$`           u$$\    )$$*                         %$$$#        \$$$$,         @$$$$.    [$$M                         ,$$! "$$~        `$$$'          B$$^        /$$)                  
               `%$$n'                   W$$]            #$8. .$$n           [email protected]        .$$$$r                    <[email protected]           [email protected]$$>    M$${                        '$$$$1        &$$$$'        '$$$$M     c$$(                        .%$z  '$$\        ;$$B          I$$&         M$$i                  
                'n$$%_.                '$$$,           _$$,   #[email protected]           t$$n        ^$$$$~                    j$$n           `$$$^   .$$$:                        :$$$$;       [email protected]         ,$$$$)    .$$$I                        _$$,   @$#        ]$$n         [email protected]$%`        .$$$"                  
                  ,[email protected]              :$$$.          ^$$)    /$$`          %$$+        +$$$$)iiiiii;             B$$+           <[email protected]   `$$$;^^^^^^^.                1$$$$'       ^$$$$&<<<<<<<<<j$$$$;    ^$$$l^^^^^^^                '@$x    v$$.       x$$n:::::I~)[email protected]).         "$$$.                  
                    :%$$B+             }$$M           W$%.    _$$,         '$$$"        r$$$$$$$$$$$f            '$$$"           f$$n    ;$$$$$$$$$$$`                #$$$%        l$$$$$$$$$$$$$$$$$$$'    ~$$$$$$$$$$8                [email protected]'    [$$"       %[email protected]$$(^.           _$$8                   
                     .i&$$#"           z$$(          i$$<     :$$_         ;$$$.        B$$$W"""""""'            "$$$.           %$$-    [$$n........                .$$$$x        {$$$$>^^^^^^^^^%$$$%     r$$r........               ~$$>     :$$_      '$$$`     ]$$)             n$$t                   
                       .-B$$j.        .$$$;         .%$W.     `$$f         ($$c        `$$$$\                    <$$#           '$$$"    n$$]                        ,$$$$]        v$$$$.        .$$$$t     B$$>                      '$$v      '$$u      :$$$.     `$$B.           [email protected]$$!                   
                         .c$$r        `$$$'         f$$~``````^$$&         M$$}        !$$$$~                    ($$\           "$$$.    B$$;                        ?$$$$;        @$$$z         "$$$$i    '$$$^                      \$$~```````@[email protected]     {$$M       W$$I           `$$$`                   
               '.         'B$$,       :$$B         ;$$$$$$$$$$$$$$.       .$$$,        \$$$$,                    z$$~           >$$M    '$$$`                        u$$$$`       `$$$$}         -$$$$`    "$$$.                     ^$$$$$$$$$$$$$$`     *$$)       <$$*           [email protected]                    
             z$$^          f$$-       ]$$x        'B$8.        r$$,       ^$$$'        8$$$$'                    %$$,           /$${    ;$$$.                        @$$$$.       l$$$$,         [email protected]     ~$$z                     .&$B'        }$$<    .$$$;       .B$$"          f$$x                    
             c$$+          #$$"       r$$[        {$$<         ?$$[       I$$8        .$$$$B                     8$$:          '@$$`    )$$*                        '$$$$#        |$$$$'        [email protected]$$$z     |$$(                     /$$i         I$$j    "$$$'        {$$r          %$$+                    
             ,$$B'        i$$j        8$$I       `@$8.         ;$$z       }$$j        ^$$$$x                     ($$r         `*$$<     #$${                        ,$$$$1        W$$$8         ^$$$$(     *$$>                    ^$$*          ^$$%    _$$8         `$$$'        '$$$"                    
              >$$B1;^`^,_c$B[.       '$$$`      .#$$,          `$$$.      u$$-        !$$$$%zzzzzzzzj            .r$$M?,^``"!f$$c`     .$$$:                        _$$$$:       '$$$$j         <$$$$i    .$$$],,,,,,,,,           c$$,          .$$$'   u$$/          v$$i        "$$$.                    
               '_*$$$$$$%rI.         ,@@@.      [@@\           [email protected]@@"      %@@:        {@@@@@@@@@@@@@)              ^(8$$$$$$$#}"       ,@@@'                        /@@@B'       ,@@@@-         [email protected]@@@"    ^@@@@@@@@@@@@&          [email protected]@v            &@@"   [email protected]@!          >@@n        [email protected]@*                     
                   .'''.                                                                                              .''`'.                                                                                                                                                                                
*/

pragma solidity 0.8.17;

import "ERC721.sol";
import "EIP2981AllToken.sol";
import "BlockList.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "MerkleProof.sol";
import "ECDSA.sol";
import "Strings.sol";

contract StateOfTheArt is ERC721, EIP2981AllToken, BlockList, Ownable, ReentrancyGuard {
    using Strings for uint256;
    //================= State Variables =================//
    // general details
    address public adminAddress;
    address payable public payoutAddress;

    // sale details
    bool public tokensSet;
    bool public preSaleOpen;
    bool public publicSaleOpen;
    bytes32 public merkleRoot;
    uint256 public mintPrice;
    uint256 public mintAllowance;
    mapping(address => uint256) internal _numMinted;
    uint16[] internal _tokenArray;

    // token uri details
    string internal _baseTokenUri;
    mapping(uint256 => string) internal _tokenUriOverrides;

    // merge details
    bool public mergeOpen;
    address public mergeSigner;
    uint256 internal _counter;

    //================= Events =================//
    event Merge(address indexed owner, uint256 indexed mergedTokenId, string indexed newTokenUri, uint256[] burnedTokens);

    //================= Modifiers =================//
    modifier adminOrOwner {
        require(msg.sender == adminAddress || msg.sender == owner(), "Address not admin or owner");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == adminAddress, "Address not admin");
        _;
    }
    //================= Constructor =================//
    constructor(
        address admin,
        address payout,
        bytes32 root,
        uint256 price,
        uint256 allowance,
        string memory initUri,
        address signer,
        address royaltyPayout,
        uint256 royaltyPerc
    )
    ERC721("STATE OF THE ART by ThankYouX", "SOTAX")
    EIP2981AllToken(royaltyPayout, royaltyPerc)
    BlockList()
    Ownable()
    ReentrancyGuard()
    {   
        // state updates
        adminAddress = admin;
        payoutAddress = payable(payout);
        merkleRoot = root;
        mintPrice = price;
        mintAllowance = allowance;
        _baseTokenUri = initUri;
        mergeSigner = signer;
    }

    //================= General Functions =================//
    /// @notice function to create token array
    /// @dev requires admin or owner
    function setTokenArray() external adminOrOwner {
        require(!tokensSet, "Token array already set");
        for (uint16 i = 1; i < 1601; i++) {
            _tokenArray.push(i);
        }
        tokensSet = true;
    }
    
    /// @notice function to renounce admin rights
    /// @dev requires admin only
    function renounceAdmin() external onlyAdmin {
        adminAddress = address(0);
    }

    /// @notice function to set admin address
    /// @dev requires owner
    function setAdminAddress(address newAdmin) external onlyOwner {
        adminAddress = newAdmin;
    }

    /// @notice function to set payout address
    /// @dev requires owner
    function setPayoutAddress(address newPayout) external onlyOwner {
        payoutAddress = payable(newPayout);
    }

    /// @notice sets the base URI
    /// @dev requires admin or owner
    function setBaseURI(string memory newUri) external adminOrOwner {
        _baseTokenUri = newUri;
    }

    /// @notice function to get total supply
    function totalSupply() external view returns(uint256) {
        return _counter;
    }

    //================= Sale Functions =================//
    /// @notice function to set the pre-sale open
    /// @dev requires admin or owner
    function openPreSale() external adminOrOwner {
        preSaleOpen = true;
        publicSaleOpen = false;
    }

    /// @notice function to set the public sale open
    /// @dev requires admin or owner
    function openPublicSale() external adminOrOwner {
        preSaleOpen = false;
        publicSaleOpen = true;
    }

    /// @notice function to close both sales
    /// @dev requires admin or owner
    function closeSales() external adminOrOwner {
        preSaleOpen = false;
        publicSaleOpen = false;
    }

    /// @notice function to set the merkle root
    /// @dev requires admin or owner
    function setMerkleRoot(bytes32 newMerkleRoot) external adminOrOwner {
        merkleRoot = newMerkleRoot;
    }

    /// @notice function to set the mint price
    /// @dev requires admin or owner
    function setMintPrice(uint256 newPrice) external adminOrOwner {
        mintPrice = newPrice;
    }

    /// @notice function to set the mint allowance
    /// @dev requires admin or owner
    function setMintAllowance(uint256 newAllowance) external adminOrOwner {
        mintAllowance = newAllowance;
    }

    /// @notice mint to owner wallet function
    /// @dev requires admin or owner
    /// @dev mints random tokens to the owner's wallet
    /// @dev useful for setting up collections
    function ownerMint(uint256 numToMint) external nonReentrant adminOrOwner {
        require(numToMint > 0, "Cannot mint zero tokens");
        require(_tokenArray.length >= numToMint, "No supply left");
        _counter += numToMint;
        _mintRandomTokens(owner(), numToMint);
    }

    /// @notice airdrop function
    /// @dev requires admin or owner
    function airdrop(address[] calldata addresses) external nonReentrant adminOrOwner {
        require(addresses.length > 0, "Cannot mint zero tokens");
        require(_tokenArray.length >= addresses.length, "No supply left");
        _counter += addresses.length;
        for (uint256 i = 0; i < addresses.length; i++) {
            _mintRandomTokens(addresses[i], 1);
        }
    }

    /// @notice mint function
    /// @dev nonreentrant and requires a sale to be open
    function mint(uint256 numToMint, bytes32[] calldata merkleProof) external payable nonReentrant {
        require(numToMint > 0, "Cannot mint zero tokens");
        require(_tokenArray.length >= numToMint, "No supply left");
        require(msg.value >= numToMint*mintPrice, "Not enough ether attached");
        require(_numMinted[msg.sender] + numToMint <= mintAllowance, "Reached mint allowance");
        require(preSaleOpen || publicSaleOpen, "Mint closed");
        if (preSaleOpen) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Not on allowlist");
        }
        _numMinted[msg.sender] += numToMint;
        _counter += numToMint;

        (bool success, ) = payoutAddress.call{value: msg.value}("");
        require(success, "payment failed");

        _mintRandomTokens(msg.sender, numToMint);
    }

    /// @notice function to get number minted per address
    function getNumMinted(address user) external view returns(uint256) {
        return _numMinted[user];
    }

    /// @notice function to mint random tokens
    /// @dev takes in recipient and number to mint
    function _mintRandomTokens(address recipient, uint256 numTokens) internal {
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 randomIndex = _getRandomIndex(_tokenArray.length);
            uint256 tokenId = uint256(_tokenArray[randomIndex]);
            _tokenArray[randomIndex] = _tokenArray[_tokenArray.length - 1];
            _tokenArray.pop();
            _safeMint(recipient, tokenId);
        }
    }

    /// @notice function to get random index
    function _getRandomIndex(uint256 maxIndex) internal view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase, block.difficulty, msg.sender, _counter)));
        return random % maxIndex;
    }

    //================= Merge Functions =================//
    /// @notice function to open merge
    /// @dev requires admin or owner
    function openMerge() external adminOrOwner {
        mergeOpen = true;
    }

    /// @notice function to close merge
    /// @dev requires admin or owner
    function closeMerge() external adminOrOwner {
        mergeOpen = false;
    }

    /// @notice function to set the merge signer
    /// @dev requires admin or owner
    function setMergeSigner(address newMergeSigner) external adminOrOwner {
        mergeSigner = newMergeSigner;
    }

    /// @notice function to merge tokens
    /// @dev takes in tokens to burn, new token uri, and a signature to verify
    /// @dev nonreentrant and requires that msg.sender is the owner of all the tokens
    function merge(uint256[] calldata tokens, string calldata uri, bytes calldata sig) external nonReentrant {
        require(mergeOpen, "Merge not open");
        bytes32 msgHash = _generateHash(tokens, uri, msg.sender);
        require(ECDSA.recover(msgHash, sig) == mergeSigner, "Invalid signature");
        for (uint256 i = 0; i < tokens.length; i++) {
            require(ownerOf(tokens[i]) == msg.sender, "Sender does not own all tokens");
            _burn(tokens[i]);
        }
        _counter++;
        _tokenUriOverrides[_counter] = uri;
        _safeMint(msg.sender, _counter);

        emit Merge(msg.sender, _counter, uri, tokens);
    }

    /// @notice function to generate hash for signature verification
    /// @dev need to use hash of the uri as packing becomes ambiguous with two variable length inputs
    function _generateHash(uint256[] memory tokens, string memory uri, address sender) internal pure returns(bytes32) {
        uint256 msgLengthBytes = ( tokens.length * 32 ) + 32 + 20;
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n", 
                msgLengthBytes.toString(), 
                tokens, 
                keccak256(bytes(uri)), 
                sender)
        );
    }

    //================= Royalty Functions =================//
    /// @notice function to change the royalty info
    /// @dev requires owner
    /// @dev this is useful if the amount was set improperly at contract creation.
    function setRoyaltyInfo(address newAddr, uint256 newPerc) external onlyOwner {
        _setRoyaltyInfo(newAddr, newPerc);
    }

    //================= BlockList =================//
    function setBlockListStatus(address operator, bool status) external onlyOwner {
        _setBlockListStatus(operator, status);
    }

    //================= Overrides =================//
    /// @dev see {ERC721.approve}
    function approve(address to, uint256 tokenId) public virtual override(ERC721) notBlocked(to) {
        ERC721.approve(to, tokenId);
    }

    /// @dev see {ERC721.setApprovalForAll}
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721) notBlocked(operator) {
        ERC721.setApprovalForAll(operator, approved);
    }

    /// @dev see {ERC165.supportsInterface}
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, EIP2981AllToken) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || EIP2981AllToken.supportsInterface(interfaceId);
    }

    /// @dev see {ERC721.tokenURI}
    /// @dev if there is an individual token override (because of merge), show that
    ///        otherwise, show base uri with token id appended
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns(string memory) {
        require(_exists(tokenId), "Query for non existent token id");
        string memory uriOverride = _tokenUriOverrides[tokenId];
        if (bytes(uriOverride).length > 0) {
            return uriOverride;
        } else {
            return string(abi.encodePacked(_baseTokenUri, tokenId.toString()));
        }
    }
    
}