// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./chainlink/VRFConsumerBase.sol";
import 'abdk-libraries-solidity/ABDKMathQuad.sol';

contract Curve is VRFConsumerBase, Ownable {
    using SafeMath for uint256;
    using ABDKMathQuad for bytes16;

    // linear bonding curve
    // 99.5% going into reserve.
    // 0.5% going to creator.

    bytes32 internal immutable keyHash;
    uint256 internal immutable fee;

    bytes16 internal constant LMIN = 0x40010000000000000000000000000000;
    bytes16 internal constant LMAX = 0x3fff0000000000000000000000000000;
    bytes16 internal constant T = 0x401124f8000000000000000000000000;
    bytes16 internal constant b = 0x3ffb2a5cd80b02065168267ecaae600a;
    bytes16 internal constant ONE_TOKEN_BYTES = 0x403abc16d674ec800000000000000000;


    struct Request {
        bool isMint;
        address _address;
        uint256 _price;
        uint256 _reserve;
        uint256 _tokenId;
    }

    mapping(bytes32 => Request) public requests;
    uint256 public nftsCount;
    bool public gameEnded;

    uint256 public ukrainianFlagPrizeMultiplier;
    uint256 public rarePrizeMultiplier;

    // this is currently 0.5%
    uint256 public constant initMintPrice = 0.00015 ether; // at 0
    // uint256 public constant mintPriceMove = 0.002 ether / 16000;
    uint256 constant CREATOR_PERCENT = 50;
    uint256 constant CHARITY_PERCENT = 150;
    uint256 constant DENOMINATOR = 1000;

    // You technically do not need to keep tabs on the reserve
    // because it uses linear pricing
    // but useful to know off-hand. Especially because this.balance might not be the same as the actual reserve
    uint256 public reserve;

    address payable public immutable creator;
    address payable public immutable charity;

    ERC721 public nft;

    address public immutable admin;

    event Minted(
        uint256 indexed tokenId,
        uint256 indexed pricePaid,
        uint256 indexed reserveAfterMint
    );
    event Burned(
        uint256 indexed tokenId,
        uint256 indexed priceReceived,
        uint256 indexed reserveAfterBurn
    );
    event Lottery(
        uint256 indexed tokenId,
        uint256 indexed lotteryId,
        bool isWinner,
        uint256 indexed prizeAmount
    );

    constructor(
        address payable _creator,
        address payable _charity,
        address _coordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _vrfFee
    )
        VRFConsumerBase(
            _coordinator, // VRF Coordinator
            _link // LINK Token
        )
    {
        require(_creator != address(0));
        require(_charity != address(0));

        creator = _creator;
        charity = _charity;

        keyHash = _keyHash;
        fee = _vrfFee; // (Varies by network)

        admin = msg.sender;
    }

    modifier NftInitialized() {
        require(address(nft) != address(0), "NFT not initialized");
        _;
    }

    function setPrizeMultipliers(uint256 _flagMultiplier, uint256 _rareMultiplier) public onlyOwner {
        require(_flagMultiplier != 0 && _rareMultiplier !=0, "Curve: Multipliers cannot be zero.");
        require(2 <= _flagMultiplier && _flagMultiplier <= 8, "Curve: Flag multiplier must be between 2 and 8");
        require(5 <= _rareMultiplier && _rareMultiplier <= 40, "Curve: Rare multiplier must be between 5 and 40");

        ukrainianFlagPrizeMultiplier = _flagMultiplier;
        rarePrizeMultiplier = _rareMultiplier;
    }

    /*
        With one mint front-runned, a front-runner will make a loss.
        With linear price increases of 0.001, it's not profitable.
        BECAUSE it costs 0.012 ETH at 50 gwei to mint (storage/smart contract costs) + 0.5% loss from creator fee.

        It becomes more profitable to front-run if there are multiple buys that can be spotted
        from multiple buyers in one block. However, depending on gas price, it depends how profitable it is.
        Because the planned buffer on the front-end is 0.01 ETH, it's not profitable to front-run any normal amounts.
        Unless, someone creates a specific contract to start bulk minting.
        To curb speculation, users can only mint one per transaction (unless you create a separate contract to do this).
        Thus, ultimately, at this stage, while front-running can be profitable,
        it is not generally feasible at this small scale.

        Thus, for the sake of usability, there's no additional locks here for front-running protection.
        A lock would be to have a transaction include the current price:
        But that means, that only one neolastic per block would be minted (unless you can guess price rises).
    */
    function mint()
        external
        payable
        virtual
        NftInitialized
        returns (bytes32 _requestId)
    {
        require(!gameEnded, "C: Game ended");
        // you can only mint one at a time.
        require(LINK.balanceOf(address(this)) >= fee, "C: Not enough LINK");
        require(msg.value > 0, "C: No ETH sent");

        uint256 mintPrice = getCurrentPriceToMint();
        require(msg.value >= mintPrice, "C: Not enough ETH sent");

        _requestId = requestRandomness(keyHash, fee);
        nftsCount++;

        // disburse
        uint256 reserveCut = getReserveCut();
        reserve = reserve.add(reserveCut);

        requests[_requestId].isMint = true;
        requests[_requestId]._address = msg.sender;
        requests[_requestId]._price = mintPrice;
        requests[_requestId]._reserve = reserve;

        bool success;
        (success, ) = creator.call{
            value: mintPrice.mul(CREATOR_PERCENT).div(DENOMINATOR)
        }("");
        require(success, "Unable to send to creator");
        (success, ) = charity.call{
            value: mintPrice.mul(CHARITY_PERCENT).div(DENOMINATOR)
        }("");
        require(success, "Unable to send to charity");

        uint256 buffer = msg.value.sub(mintPrice); // excess/padding/buffer
        if (buffer > 0) {
            (success, ) = msg.sender.call{value: buffer}("");
            require(success, "Unable to send buffer back");
        }

        return _requestId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        if (requests[requestId].isMint) {
            // mint first to increase supply
            uint256 tokenId = nft.mint(
                requests[requestId]._address,
                randomness
            );
            emit Minted(
                tokenId,
                requests[requestId]._price,
                requests[requestId]._reserve
            );
        } else {
            // Burn
            uint256 burnPrice;
            uint256 tokenId = requests[requestId]._tokenId;

            if (isRare(tokenId)) {
                burnPrice = getCurrentPriceToBurn().mul(rarePrizeMultiplier);
            } else if (isUkrainianFlag(tokenId)) {
                burnPrice = getCurrentPriceToBurn().mul(ukrainianFlagPrizeMultiplier);
            } else {
                require(reserve > 0, "Reserve should be > 0");

                string memory lotteryImage = nft.generateSVGofTokenById(
                    randomness
                );
                string memory tokenImage = nft.generateSVGofTokenById(tokenId);
                if (
                    keccak256(abi.encodePacked(lotteryImage)) ==
                    keccak256(abi.encodePacked(tokenImage))
                ) {
                    burnPrice = reserve;
                    gameEnded = true;
                    emit Lottery(tokenId, randomness, true, burnPrice);
                }
            }

            nft.burn(requests[requestId]._address, tokenId);
            nftsCount--;
            emit Lottery(tokenId, randomness, false, burnPrice);

            reserve = reserve.sub(burnPrice);
            (bool success, ) = requests[requestId]._address.call{
                value: burnPrice
            }("");
            require(success, "Unable to send burnPrice");

            emit Burned(tokenId, burnPrice, reserve);
        }
    }

    function burn(uint256 tokenId) external virtual NftInitialized {
        bytes32 _requestId = requestRandomness(keyHash, fee);

        requests[_requestId]._address = msg.sender;
        requests[_requestId]._tokenId = tokenId;
    }

    function isRare(uint256 tokenId) public pure returns (bool) {
        bytes memory bhash = abi.encodePacked(bytes32(tokenId));
        for (uint256 i = 0; i < 6; i++) {
            if (toUint8(bhash, i) / 51 == 5) {
                return true;
            }
        }
        return false;
    }

    function isUkrainianFlag(uint256 tokenId) public pure returns (bool) {
        bytes memory bhash = abi.encodePacked(bytes32(tokenId));

        if (toUint8(bhash, 0) / 51 == 1 && toUint8(bhash, 1) / 51 == 3) {
            return true;
        } else if (toUint8(bhash, 2) / 51 == 1 && toUint8(bhash, 3) / 51 == 3) {
            return true;
        } else if (toUint8(bhash, 4) / 51 == 1 && toUint8(bhash, 5) / 51 == 3) {
            return true;
        }

        return false;
    }

    // helper function for generation
    // from: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    // if supply 0, mint price = 0.002
    function getCurrentPriceToMint() public view virtual returns (uint256) {
        return ABDKMathQuad.toUInt(ABDKMathQuad.mul(ABDKMathQuad.fromUInt(initMintPrice), ABDKMathQuad.add(
                LMIN, 
                ABDKMathQuad.mul(
                    ABDKMathQuad.sub(LMAX, LMIN), 
                    ABDKMathQuad.exp(
                        ABDKMathQuad.neg(
                            ABDKMathQuad.div(
                                ABDKMathQuad.mul(ABDKMathQuad.fromUInt(nftsCount), ABDKMathQuad.fromUInt(nftsCount)),
                                ABDKMathQuad.mul(b, T)
                            )
                        )
                    )
                )
            )
            ));
    }

    // helper function for legibility
    function getReserveCut() public view virtual returns (uint256) {
        return getCurrentPriceToBurn();
    }

    // if supply 1, then burn price = 0.000995
    function getCurrentPriceToBurn() public view virtual returns (uint256) {
        uint256 burnPrice = getCurrentPriceToMint();
        burnPrice -= (burnPrice.mul(CREATOR_PERCENT.add(CHARITY_PERCENT))).div(
            DENOMINATOR
        );
        return burnPrice;
    }

    function initNFT(ERC721 _nft) external onlyOwner {
        require(address(nft) == address(0), "Already initiated");

        nft = _nft;
    }
}