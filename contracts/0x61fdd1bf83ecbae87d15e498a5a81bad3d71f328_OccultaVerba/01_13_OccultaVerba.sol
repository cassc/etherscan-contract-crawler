// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OccultaVerba is Ownable, ERC721 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    enum TokenType { CMinor, AMinor, FSharpMajor, Prize }

    uint256 public constant price = 0.1 ether;
    bool public isMintable;
    uint256 public maxSupply;
    string public baseTokenURI = "ipfs://QmeJq9kntM8YGjfjcVAXPb4dC97ZgaExcZN5u9K8zqRNL6/";
    address public winner;

    bytes32 private _secret;
    address private _payoutAddress;
    string private _clueCMinor;
    string private _clueAMinor;
    string private _clueFSharpMinor;
    uint256 private _winnerSentAmount;
    bool private _prizeTokenSentToWinner;
    Counters.Counter private _tokenIdTracker;

    mapping(TokenType => Counters.Counter) minted;
    mapping(uint256 => TokenType) tokenTypeById;

    constructor(
        bytes32 secret, 
        uint256 max, 
        address payoutAddress, 
        string memory clueCMinor, 
        string memory clueAMinor, 
        string memory clueFSharpMinor
    ) ERC721("OccultaVerba", "VRBA") {
        _secret = secret;
        maxSupply = max;
        _payoutAddress = payoutAddress;
        _clueCMinor = clueCMinor;
        _clueAMinor = clueAMinor;
        _clueFSharpMinor = clueFSharpMinor;
        _doMint(TokenType.Prize);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _getUrl(tokenTypeById[tokenId]);
    }

    function _getUrl(TokenType t) private view returns (string memory) {
        if (t == TokenType.CMinor) return string(abi.encodePacked(baseTokenURI, "cminor"));
        if (t == TokenType.AMinor) return string(abi.encodePacked(baseTokenURI, "aminor"));
        if (t == TokenType.FSharpMajor) return string(abi.encodePacked(baseTokenURI, "fsharpmajor"));
        if (t == TokenType.Prize) return string(abi.encodePacked(baseTokenURI, "prize"));
        else return "";
    }

    function openMinting() public onlyOwner {
        require(isMintable == false, "Minting needs to be closed first");
        isMintable = true;
    }

    function closeMinting() public onlyOwner {
        require(isMintable, "Minting needs to be open first");
        isMintable = false;
    }

    function claim(bool cm, bool am, bool fsharp) public payable {
        require(msg.sender != owner(), "Owner can not call this function");
        require(isMintable, "Minting is not allowed yet");
        require(cm || am || fsharp, "Need to pick at least one song");

        uint256 counter;

        if (cm) {
            require(minted[TokenType.CMinor].current() < maxSupply, "Sold out");
            counter++;
            _doMint(TokenType.CMinor);
        }
        if (am) {
            require(minted[TokenType.AMinor].current() < maxSupply, "Sold out");
            counter++;
            _doMint(TokenType.AMinor);
        }
        if (fsharp) {
            require(minted[TokenType.FSharpMajor].current() < maxSupply, "Sold out");
            counter++;
            _doMint(TokenType.FSharpMajor);
        }

        uint256 total = price.mul(counter);
        require(msg.value == total, "Incorrect price");
    }

    function _doMint(TokenType tokenType) private {
        _tokenIdTracker.increment();
        uint256 tokenId = _tokenIdTracker.current();
        tokenTypeById[tokenId] = tokenType;
        minted[tokenType].increment();
        _safeMint(msg.sender, tokenId);
    }

    function guess(string memory solution) public view returns (bool) {
        require(balanceOf(msg.sender) > 0, "Need to own one or more songs");
        return _isGuessCorrect(solution, _secret);
    }

    function _isGuessCorrect(string memory secretGuess, bytes32 secret) private pure returns (bool) {
        bytes32 solutionHash = keccak256(abi.encodePacked(secretGuess));
        bytes32 solutionDoubleHash = keccak256(abi.encodePacked(solutionHash));
        return solutionDoubleHash == secret;
    }

    function markSenderAsWinner(string memory secretGuess) public {
        require(winner == address(0), "Has been solved already");
        require(msg.sender != owner(), "Owner can not call this function");
        require(balanceOf(msg.sender) > 0, "Need to own one or more songs");

        bool isGuessCorrect = _isGuessCorrect(secretGuess, _secret);
        require(isGuessCorrect, "Incorrect guess");
        
        winner = msg.sender;
    }

    function sendPrizeAndEthToWinner() public { 
        require(winner != address(0), "No winner yet");
        require(winner == msg.sender, "You need to be the winner");

        uint256 amountToPay = _getWinnerMaxAmount().sub(_winnerSentAmount); 
        require(amountToPay > 0, "Amount is 0");

        _winnerSentAmount = _winnerSentAmount.add(amountToPay); 

        if (_prizeTokenSentToWinner == false) {
            _prizeTokenSentToWinner = true;
            _safeTransfer(ownerOf(1), msg.sender, 1, "");
        }

        (bool success, ) = msg.sender.call{value: amountToPay}("");
        require(success, "Transfer failed");
    }

    function withdrawForTeam() public onlyOwner { 
        uint256 amountToPay = address(this).balance
            .sub(_getWinnerMaxAmount())
            .add(_winnerSentAmount);

        require(amountToPay > 0, "Amount is 0");
        
        (bool success, ) = _payoutAddress.call{value: amountToPay}("");
        require(success, "Transfer failed");
    }

    function _getWinnerMaxAmount() private view returns (uint256) {
        uint256 numberOfSoldTokens = getTotalTokenCount().sub(1);
        return numberOfSoldTokens.mul(price).mul(5).div(100);
    }

    function getTokenTypeById(uint256 tokenId) public view returns (TokenType tokenType) {
        require(_exists(tokenId), "Token not minted");
        tokenType = tokenTypeById[tokenId];
    }

    function getNumberOfTokensByType(TokenType tokenType) public view returns (uint256) {
        return minted[tokenType].current();
    }

    function getTotalTokenCount() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function getTokenIdsByAddress(address inputAddress) public view returns (uint256[] memory) {
        uint256 limit = balanceOf(inputAddress);
        if (limit == 0) return new uint256[](0);
        
        uint256[] memory tokens = new uint256[](limit);
        uint256 cnt;

        for (uint256 i = 1; i <= maxSupply.mul(3); i++) {
            if (ownerOf(i) == inputAddress) {
                tokens[cnt] = i;
                if (cnt == limit - 1) {
                    break;
                } else {
                    cnt++;
                }
            }
        }

        return tokens;
    }

    function getClue(uint256 tokenId) public view returns (string memory) {
        require(ownerOf(tokenId) == msg.sender, "You need to own the token"); 

        TokenType tokenType = tokenTypeById[tokenId];
        require(tokenType != TokenType.Prize, "There are only clues for songs");

        if (tokenType == TokenType.AMinor) return _clueAMinor;
        if (tokenType == TokenType.CMinor) return _clueCMinor;
        if (tokenType == TokenType.FSharpMajor) return _clueFSharpMinor;
        else return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(msg.sender != owner(), "Owner can not call this function");
        super.approve(to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(msg.sender != owner(), "Owner can not call this function");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(msg.sender != owner(), "Owner can not call this function");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != owner(), "Owner can not call this function");
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(msg.sender != owner(), "Owner can not call this function");
        super.transferFrom(from, to, tokenId);
    }

    function renounceOwnership() public override onlyOwner {
        require(false, "Not supported");
        super.renounceOwnership();
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        if (ownerOf(1) == owner()) {
            _safeTransfer(owner(), newOwner, 1, "");
        }
        super.transferOwnership(newOwner);
    }

    function changePayoutAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Address is empty");
        _payoutAddress = newAddress;
    }
}