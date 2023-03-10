// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "ERC721A/ERC721A.sol";
import "chainlink/ConfirmedOwner.sol";
import "chainlink/VRFV2WrapperConsumerBase.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "solmate/utils/LibString.sol";

error SaleNotLive();
error BadState();
error ExceedsMaxMintsPerTx(uint256 attemptedMints, uint256 maxMintsPerTx);
error ExceedsMaxSupply(uint256 potentialSupply, uint256 maxSupply);
error IncorrectFundsSent(uint256 fundsSent, uint256 fundsRequired);
error RejectZeroAddress();
error TokenAlreadyClaimed(uint256 tokenId);
error WrongOwner(uint256 tokenId);

contract CreatureDriveThruCards is
    ERC721A,
    VRFV2WrapperConsumerBase,
    ConfirmedOwner
{
    IERC721 creatureWorld = IERC721(0xc92cedDfb8dd984A89fb494c376f9A48b999aAFc);

    uint256 private constant MAX_SUPPLY = 10000;
    uint256 private constant MINT_PRICE = 0.01 ether;
    uint256 private constant MAX_MINTS_PER_TX = 10;

    uint256 private seed;
    string private tokenBaseURI;
    address private withdrawalAddress;

    mapping(uint256 => bool) public claimedCreatures;

    enum SaleState {
        CLOSED,
        CREATURELIST,
        PUBLIC
    }

    SaleState public saleState;

    event SetTokenBaseURI(string indexed tokenBaseURI);
    event UpdateWithdrawalAddress(address indexed newAddress);

    constructor(
        address linkAddress,
        address wrapperAddress
    )
        ERC721A("CDT Cards", "CDTC")
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        LINK_ADDRESS = linkAddress;
        setWithdrawalAddress(msg.sender);
    }

    function freeMint(uint256 amount, uint256[] memory tokenIds) external {
        require(tokenIds.length == amount, "amount does not match");
        if (saleState == SaleState.CLOSED) revert SaleNotLive();
        uint256 newSupply = totalSupply() + amount;
        if (amount > MAX_MINTS_PER_TX) {
            revert ExceedsMaxMintsPerTx(amount, MAX_MINTS_PER_TX);
        }
        if (newSupply > MAX_SUPPLY) {
            revert ExceedsMaxSupply(newSupply, MAX_SUPPLY);
        }

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (creatureWorld.ownerOf(tokenIds[i]) != msg.sender) {
                revert WrongOwner(tokenIds[i]);
            }
            if (claimedCreatures[tokenIds[i]]) {
                revert TokenAlreadyClaimed(tokenIds[i]);
            }
        }

        _mint(msg.sender, amount);

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            claimedCreatures[tokenIds[i]] = true;
        }
    }

    function publicMint(uint256 amount) external payable {
        if (saleState != SaleState.PUBLIC) revert SaleNotLive();
        uint256 newSupply = totalSupply() + amount;
        if (amount > MAX_MINTS_PER_TX) {
            revert ExceedsMaxMintsPerTx(amount, MAX_MINTS_PER_TX);
        }
        if (newSupply > MAX_SUPPLY) {
            revert ExceedsMaxSupply(newSupply, MAX_SUPPLY);
        }
        if (msg.value != amount * MINT_PRICE) {
            revert IncorrectFundsSent(msg.value, amount * MINT_PRICE);
        }
        _mint(msg.sender, amount);
    }

    function setTokenBaseURI(string memory tokenBaseURI_) external onlyOwner {
        tokenBaseURI = tokenBaseURI_;
        emit SetTokenBaseURI(tokenBaseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    function withdrawFunds() external onlyOwner {
        (bool sent, ) = payable(withdrawalAddress).call{
            value: address(this).balance
        }("");
        require(sent, "Withdraw failed");
    }

    function setSaleState(uint256 state) external onlyOwner {
        if (state > uint256(SaleState.PUBLIC)) revert BadState();
        saleState = SaleState(state);
    }

    function setWithdrawalAddress(address withdrawalAddress_) public onlyOwner {
        if (withdrawalAddress_ == address(0)) {
            revert RejectZeroAddress();
        }
        withdrawalAddress = withdrawalAddress_;
        emit UpdateWithdrawalAddress(withdrawalAddress_);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        return _getMetadata(tokenId);
    }

    function _getMetadata(
        uint256 tokenId
    ) private view returns (string memory) {
        string memory baseURI = _baseURI();

        require(bytes(baseURI).length > 0, "tokenBaseURI not set");
        require(seed != 0, "random words not requested");

        uint256[] memory metadata = new uint256[](MAX_SUPPLY);

        for (uint256 i = 0; i < MAX_SUPPLY; i += 1) {
            metadata[i] = i;
        }

        for (uint256 i = 1; i < MAX_SUPPLY; i += 1) {
            uint256 j = (uint256(keccak256(abi.encode(seed, i))) %
                (MAX_SUPPLY));

            if (j >= 1 && j < MAX_SUPPLY) {
                (metadata[i], metadata[j]) = (metadata[j], metadata[i]);
            }
        }

        return string.concat(baseURI, LibString.toString(metadata[tokenId]));
    }

    // Chainlink params
    uint256[] public requestIds;
    uint256 public lastRequestId;

    address immutable LINK_ADDRESS;

    mapping(uint256 => RequestStatus) public s_requests;

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    function requestRandomWords(
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords
    ) external onlyOwner returns (uint256 requestId) {
        require(seed == 0, "words already requested");
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        _updateSeed(_randomWords[0]);
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function _updateSeed(uint256 newSeed) private {
        seed = newSeed;
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(LINK_ADDRESS);
        require(
            link.transfer(withdrawalAddress, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}