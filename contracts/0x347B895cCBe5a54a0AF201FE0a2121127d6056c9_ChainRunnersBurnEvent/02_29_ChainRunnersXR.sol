// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./core/ERC721AClaimable.sol";
import "./interfaces/IChainRunnersRenderer.sol";
import "./interfaces/IChainRunners.sol";

/*
               ::::                                                                                                                                                  :::#%=
               @*==+-                                                                                                                                               ++==*=.
               #+=#=++..                                                                                                                                        ..=*=*+-#:
                :=+++++++=====================================:    .===============================================. .=========================================++++++++=
                 .%-+%##+=--==================================+=..=+-=============================================-+*+======================================---+##+=#-.
                   [email protected]@%[email protected]@@%+++++++++++++++++++++++++++%#++++++%#+++#@@@#[email protected]@%[email protected]#+.=+*@*+*@@@@*+++++++++++++++++++++++%@@@#+++#@@+++=
                    -*-#%@@%%%=*%@%*++=++=+==+=++=++=+=++=++==#@%#%#+++=+=*@%*+=+==+=+++%*[email protected]%%#%#++++*@%#++=++=++=++=+=++=++=+=+*%%*==*%@@@*:%=
                     :@:[email protected]@@@@@*+++%@@*+===========+*=========#@@========+#%==========*@========##*#*+=======*@##*======#@#+=======*#*============+#%++#@@%#@@#++=.
                      .*+=%@%*%@%##[email protected]@%#=-==-=--==*%=========*%==--=--=-====--=--=-=##=--=-=--%%%%%+=-=--=-=*%=--=--=-=#%=--=----=#%=--=-=--=-+%#+==#%@@*#%@=++.
                        +%.#@@###%@@@@@%*---------#@%########@%*---------------------##---------------------##---------%%*[email protected]@#---------+#@=#@@#[email protected]@%*++-
                        .:*+*%@#+=*%@@@*=-------=#%#=-------=%*---------=*#*--------#+=--------===--------=#%*-------=#%*[email protected]%#--------=%@@%#*+=-+#%*+*:.
       ====================%*[email protected]@%#==+##%@*[email protected]#[email protected]@*-------=*@[email protected]@*[email protected][email protected]=--------*@@+-------+#@@%#==---+#@.*%====================
     :*=--==================-:=#@@%*===+*@%+=============%%%@=========*%@*[email protected]+=--=====+%@[email protected][email protected]========*%@@+======%%%**+=---=%@#=:-====================-#-
       +++**%@@@#*****************@#*=---=##%@@@@@@@@@@@@@#**@@@@****************%@@*[email protected]#***********#@************************************+=------=*@#*********************@#+=+:
        .-##=*@@%*----------------+%@%=---===+%@@@@@@@*+++---%#++----------------=*@@*+++=-----------=+#=------------------------------------------+%+--------------------+#@[email protected]
         :%:#%#####+=-=-*@@+--=-==-=*@=--=-==-=*@@#*[email protected][email protected]%===-==----+-==-==--+*+-==-==---=*@@@@@@%#===-=-=+%@%-==-=-==-#@%=-==-==--+#@@@@@@@@@@@@*+++
        =*=#@#=----==-=-=++=--=-==-=*@=--=-==-=*@@[email protected]===-=--=-*@@*[email protected]=--=-==--+#@-==-==---+%-==-==---=+++#@@@#--==-=-=++++-=--=-===#%[email protected]@@%.#*
        +#:@%*===================++%#=========%@%=========#%=========+#@%+=======#%==========*@#=========*%=========+*+%@@@+========+*[email protected]@%+**+================*%#*=+=
       *++#@*+=++++++*#%*+++++=+++*%%++++=++++%%*=+++++++##*=++++=++=%@@++++=++=+#%++++=++++#%@=+++++++=*#*+++++++=#%@@@@@*++=++++=#%@*[email protected]#*****=+++++++=+++++*%@@+:=+=
    :=*=#%#@@@@#%@@@%#@@#++++++++++%%*+++++++++++++++++**@*+++++++++*%#++++++++=*##++++++++*%@%+++++++++##+++++++++#%%%%%%++++**#@@@@@**+++++++++++++++++=*%@@@%#@@@@#%@@@%#@++*:.
    #*:@#=-+%#+:=*@*[email protected]%#++++++++#%@@#*++++++++++++++#%@#*++++++++*@@#[email protected]#++++++++*@@#+++++++++##*+++++++++++++++++###@@@@++*@@#+++++++++++++++++++*@@#=:+#%[email protected]*=-+%*[email protected]=
    ++=#%#+%@@%=#%@%#+%%#++++++*#@@@%###**************@@@++++++++**#@##*********#*********#@@#++++++***@#******%@%#*++**#@@@%##+==+++=*#**********%%*++++++++#%#=%@@%+*%@%*+%#*=*-
     .-*+===========*@@+++++*%%%@@@++***************+.%%*++++#%%%@@%=:=******************[email protected]@#+++*%%@#==+***--*@%*++*%@@*===+**=--   -************[email protected]%%#++++++#@@@*==========*+-
        =*******##.#%#++++*%@@@%+==+=             *#-%@%**%%###*====**-               [email protected]:*@@##@###*==+**-.-#[email protected]@#*@##*==+***=                     =+=##%@*+++++*%@@#.#%******:
               ++++%#+++*#@@@@+++==.              **[email protected]@@%+++++++===-                 -+++#@@+++++++==:  :+++%@@+++++++==:                          [email protected]%##[email protected]@%++++
             :%:*%%****%@@%+==*-                .%==*====**+...                      #*.#+==***....    #+=#%+==****:.                                ..-*=*%@%#++*#%@=+%.
            -+++#%+#%@@@#++===                  [email protected]*++===-                            #%++===           %#+++===                                          =+++%@%##**@@*[email protected]:
          .%-=%@##@@%*==++                                                                                                                                 .*==+#@@%*%@%=*=.
         .+++#@@@@@*++==.                                                                                                                                    -==++#@@@@@@=+%
       .=*=%@@%%%#=*=.                                                                                                                                          .*+=%@@@@%+-#.
       @[email protected]@@%:++++.                                                                                                                                              -+++**@@#+*=:
    .-+=*#%%++*::.                                                                                                                                                  :+**=#%@#==#
    #*:@*+++=:                                                                                                                                                          [email protected]*++=:
  :*-=*=++..                                                                                                                                                             .=*=#*.%=
 +#.=+++:                                                                                                                                                                   ++++:+#
*+=#-::                                                                                                                                                                      .::*+=*

*/

contract ChainRunnersXR is Ownable, ERC721AClaimable, ReentrancyGuard {

    address public genesisContractAddress;
    address public xrRendererContractAddress;

    uint256 public immutable amountForDevs;
    uint256 public immutable mintCollectionSize;

    uint256 public numAvailableTokens = 10000;
    mapping(uint => uint) private _availableTokens;

    mapping(uint256 => uint256) tokenIdToContentIdMapping;

    uint256 public publicSaleStartTimestamp;
    uint256 public allowlistStartTimestamp;
    uint256 public claimStartTimestamp;

    mapping(address => uint256) public allowlist;
    bytes32 private allowlistMerkleRoot;

    uint256[40] claimedBitMap;

    uint256 public constant MAX_PER_ADDRESS_DURING_ALLOWLIST_MINT = 1;
    uint256 public constant MAX_PER_TRANSACTION_DURING_PUBLIC = 5;
    uint256 public constant PRICE_PER_TOKEN = 0.1 ether;
    uint256 public constant MAX_BATCH_SIZE = 5;

    uint256 revealSeed;

    uint256 public burningStartTimestamp;

    constructor(
        uint256 mintCollectionSize_,
        uint256 amountForDevs_,
        address genesisContractAddress_,
        address xrRendererContractAddress_
    ) ERC721AClaimable("Chain Runners XR", "XR") {
        mintCollectionSize = mintCollectionSize_;
        amountForDevs = amountForDevs_;
        genesisContractAddress = genesisContractAddress_;
        xrRendererContractAddress = xrRendererContractAddress_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller is another contract");
        _;
    }

    // SALE CONFIG FUNCTIONS
    function setAllowlistSaleStartTimestamp(uint256 _allowlistStartTimestamp) external onlyOwner {
        allowlistStartTimestamp = _allowlistStartTimestamp;
    }

    function setPublicSaleStartTimestamp(uint256 _publicSaleStartTimestamp) external onlyOwner {
        publicSaleStartTimestamp = _publicSaleStartTimestamp;
    }

    function setClaimStartTimestamp(uint256 _claimStartTimestamp) external onlyOwner {
        claimStartTimestamp = _claimStartTimestamp;
    }

    function isPublicSaleActive() public view returns (bool) {
        return
        publicSaleStartTimestamp != 0 &&
        block.timestamp >= publicSaleStartTimestamp;
    }

    function isAllowlistSaleActive() public view returns (bool) {
        return
        allowlistStartTimestamp != 0 &&
        block.timestamp >= allowlistStartTimestamp;
    }

    function isClaimActive() public view returns (bool) {
        return
        claimStartTimestamp != 0 &&
        block.timestamp >= claimStartTimestamp;
    }

    function setAllowlistMerkleRoot(bytes32 _root) external onlyOwner {
        allowlistMerkleRoot = _root;
    }

    function setXRRenderingContractAddress(address _xrRenderingContractAddress) public onlyOwner {
        xrRendererContractAddress = _xrRenderingContractAddress;
    }

    function reveal(uint256 _revealSeed) external onlyOwner {
        revealSeed = _revealSeed;
    }

    // MINTING FUNCTIONS
    function mintDev(uint256 _quantity) external onlyOwner {
        require(
            _totalMinted() + _quantity <= mintCollectionSize,
            "too many already minted before dev mint"
        );
        require(
            _quantity % MAX_BATCH_SIZE == 0,
            "can only mint a multiple of the maxBatchSize"
        );
        require(_quantity <= amountForDevs, "quantity is too high");

        uint256 numChunks = _quantity / MAX_BATCH_SIZE;
        for (uint256 i = 0; i < numChunks; i++) {
            _mintRandom(msg.sender, MAX_BATCH_SIZE);
        }
    }

    function mintAllowlist(uint256 _quantity, bytes32[] calldata _merkleProof) external payable callerIsUser returns (uint256) {
        require(isAllowlistSaleActive(), "allowlist sale has not begun yet");
        require(MerkleProof.verify(_merkleProof, allowlistMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "not on allowlist");
        require(allowlist[msg.sender] + _quantity <= MAX_PER_ADDRESS_DURING_ALLOWLIST_MINT, "not eligible for allowlist mint");
        require(_totalMinted() + _quantity <= (mintCollectionSize - amountForDevs), "reached max supply");

        uint256 totalCost = uint256(PRICE_PER_TOKEN * _quantity);
        unchecked {
            allowlist[msg.sender] += _quantity;
        }
        _mintRandom(msg.sender, _quantity);
        refundIfOver(totalCost);
        return _currentMintIndex - _quantity;
    }

    function mintPublic(uint256 _quantity) external payable callerIsUser returns (uint256) {
        require(isPublicSaleActive(), "public sale has not begun yet");
        require(_totalMinted() + _quantity <= (mintCollectionSize - amountForDevs), "reached max supply");
        require(_quantity <= MAX_PER_TRANSACTION_DURING_PUBLIC, "quantity too high");

        _mintRandom(msg.sender, _quantity);
        refundIfOver(PRICE_PER_TOKEN * _quantity);
        return _currentMintIndex - _quantity;
    }

    /**
    * Mint `_numToMint` tokens. Use Fisher Yates to draw a uniformly random
    * contentId to associate with each tokenId.
    */
    function _mintRandom(address _to, uint _numToMint) internal {
        uint updatedNumAvailableTokens = numAvailableTokens;
        for (uint256 i; i < _numToMint; i++) {
            uint256 contentId = getRandomAvailableContentId(_to, updatedNumAvailableTokens--);
            tokenIdToContentIdMapping[_currentMintIndex+i] = contentId;
        }
        _safeMint(_to, _numToMint);
        numAvailableTokens = updatedNumAvailableTokens;
    }

    function getRandomAvailableContentId(address _to, uint _updatedNumAvailableTokens)
    internal
    returns (uint256)
    {
        uint256 randomNum = randomNumber(_to, _updatedNumAvailableTokens);
        uint256 randomIndex = randomNum % _updatedNumAvailableTokens;
        return getAvailableTokenAtIndex(randomIndex, _updatedNumAvailableTokens);
    }

    function randomNumber(address _to, uint _updatedNumAvailableTokens) internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encode(
                    _to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    address(this),
                    _updatedNumAvailableTokens
                )
            )
        );
    }

    // Implements https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle.  Code from https://github.com/erc721r/ERC721R/blob/main/contracts/ERC721R.sol
    function getAvailableTokenAtIndex(uint256 _indexToUse, uint _updatedNumAvailableTokens)
    internal
    returns (uint256)
    {
        uint256 valAtIndex = _availableTokens[_indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = _indexToUse;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = _updatedNumAvailableTokens - 1;
        if (_indexToUse != lastIndex) {
            // Replace the value at indexToUse, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            uint256 lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                _availableTokens[_indexToUse] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                _availableTokens[_indexToUse] = lastValInArray;
                // Gas refund courtesy of @dievardump
                delete _availableTokens[lastIndex];
            }
        }

        return result;
    }

    // CLAIM FUNCTIONS
    struct ClaimData {
        address to;
        uint256 start;
        uint256 count;
    }

    /**
    * Claim all tokens for sender.
    */
    function claimAll() external {
        require(isClaimActive(), "claim is not active");
        address owner = _msgSender();
        IChainRunners genesisContract = IChainRunners(genesisContractAddress);
        uint256 balance = genesisContract.balanceOf(owner);
        ClaimData memory batch;
        unchecked {
            for (uint256 i; i < balance; i++) {
                uint256 tokenId = genesisContract.tokenOfOwnerByIndex(owner, i);
                if (!isClaimed(tokenId)) {
                    if (batch.start == 0) {
                        batch.to = owner;
                        batch.start = tokenId;
                        batch.count = 1;
                    } else if (((batch.start+batch.count) != tokenId) || (batch.count == MAX_BATCH_SIZE)) {
                        _claim(batch.to, batch.start, batch.count);
                        batch.start = tokenId;
                        batch.count = 1;
                    } else {
                        batch.count++;
                    }
                    if (i == balance - 1) {
                        // Claim last batch
                       _claim(batch.to, batch.start, batch.count);
                    }
                    _setClaimed(tokenId);
                }
            }
        }
    }

    function claimsRemaining(address owner) public view returns (uint256) {
        IChainRunners genesisContract = IChainRunners(genesisContractAddress);
        uint256 balance = genesisContract.balanceOf(owner);
        unchecked {
            uint256 _claimsRemaining;
            for (uint256 i; i < balance; i++) {
                uint256 tokenId = genesisContract.tokenOfOwnerByIndex(owner, i);
                if (!isClaimed(tokenId)) {
                    _claimsRemaining++;
                }
            }
            return _claimsRemaining;
        }
    }

    function isClaimed(uint256 _tokenId) public view returns (bool) {
        uint256 claimedWordIndex = _tokenId / 256;
        uint256 claimedBitIndex = _tokenId % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 _tokenId) internal {
        uint256 claimedWordIndex = _tokenId / 256;
        uint256 claimedBitIndex = _tokenId % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function refundIfOver(uint256 _price) private {
        require(msg.value >= _price, "Need to send more ETH.");
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    // RENDERING FUNCTIONS
    function getDna(uint256 _tokenId) public view returns (uint256) {
        IChainRunners genesisContract = IChainRunners(genesisContractAddress);
        uint256 dna_;
        if (_tokenId <= mintCollectionSize) {
            dna_ = genesisContract.getDna(_tokenId);
        } else {
            uint256 contentId = tokenIdToContentIdMapping[_tokenId];
            dna_ = uint256(keccak256(abi.encodePacked(
                revealSeed + (contentId % mintCollectionSize)
            )));
        }
        return dna_;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (xrRendererContractAddress == address(0) || revealSeed == 0) {
            return '';
        }
        IChainRunnersRenderer renderer = IChainRunnersRenderer(xrRendererContractAddress);
        ChainRunnersTypes.ChainRunner memory runner;
        runner.dna = getDna(_tokenId);
        return renderer.tokenURI(_tokenId, runner);
    }

    // MISC FUNCTIONS
    function withdraw() public onlyOwner {
        (bool succ,) = payable(msg.sender).call{value : address(this).balance}("");
        require(succ, "transfer failed");
    }

    function ownershipStartTimestamp(uint256 _tokenId) public view returns (uint256) {
        (TokenOwnership memory ownership, ) = _ownershipOf(_tokenId);
        return ownership.startTimestamp;
    }

    function burn(uint256 tokenId) external {
        require(isBurningActive(), "burning not active");
        _burn(tokenId, true);
    }

    function isBurningActive() public view returns (bool) {
        return
        burningStartTimestamp != 0 &&
        block.timestamp >= burningStartTimestamp;
    }

    function setBurningStartTimestamp(uint256 _timestamp) public {
        burningStartTimestamp = _timestamp;
    }
}