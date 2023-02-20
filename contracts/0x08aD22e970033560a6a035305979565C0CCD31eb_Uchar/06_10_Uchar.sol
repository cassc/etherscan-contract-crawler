/*

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░                                                        ░░
░░    A A A A A    B B B B B    C C C C C    D D D D D    ░░
░░   A .  .  . A  . .  B  . B  C .  .  . .  . .  D  . D   ░░
░░   A  . . .  A  .  . B .  B  C  . . .  .  .  . D .  D   ░░
░░   A   ...   A  .   .B.   B  C   ...   .  .   .D.   D   ░░
░░    A A A A A    . . B B B    . . . . .    . . D . D    ░░
░░   A   ...   A  .   .B.   B  C   ...   .  .   .D.   D   ░░
░░   A  . . .  A  .  . B .  B  C  . . .  .  .  . D .  D   ░░
░░   A .  .  . A  . .  B  . B  C .  .  . .  . ,  D  . D   ░░
░░    . . . . .    B B B B B    C C C C C    D D D D D    ░░
░░                                                        ░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISegments.sol";
import "./interfaces/IERC4906.sol";
import "./libraries/Utilities.sol";
import "./libraries/Renderer.sol";

contract Uchar is ERC721A, Ownable, IERC4906 {
    event CountdownExtended(uint256 _finalBlock);
    event ComboDestroyed(address indexed _from, string _word);
    event ComboCreated(address indexed _from, string _word, uint256 _points);

    ISegments private segments;

    uint256 public price = 3000000000000000; //.003 eth
    bool public isCombinable = false;
    uint256 public finalMintingBlock;

    struct Combo {
        string word;
        uint256 points;
        uint256 color;
    }

    mapping(uint256 => Combo) public combos;
    mapping(string => bool) public combinedWords;

    constructor(address _segments) ERC721A("UCHARS", "UCHARS") {
        segments = ISegments(_segments);
    }

    function mint(uint256 quantity) public payable {
        require(msg.value >= quantity * price, "Not enough ETH");
        handleMint(msg.sender, quantity);
    }

    function handleMint(address recipient, uint256 quantity) internal {
        uint256 supply = _totalMinted();
        if (supply >= 1000) {
            require(
                utils.secondsRemaining(finalMintingBlock) > 0,
                "Mint is closed"
            );
            if (supply < 5000 && (supply + quantity) >= 5000) {
                finalMintingBlock = block.timestamp + 24 hours;
                emit CountdownExtended(finalMintingBlock);
            }
        } else if (supply + quantity >= 1000) {
            finalMintingBlock = block.timestamp + 24 hours;
            emit CountdownExtended(finalMintingBlock);
        }
        _mint(recipient, quantity);
    }

    function combine(uint256[] memory tokens) public {
        require(isCombinable, "Combining not active");
        require(tokens.length < 9, "Too many letters");
        uint256 sum;
        string memory word;
        for (uint256 i = 0; i < tokens.length; i++) {
            require(ownerOf(tokens[i]) == msg.sender, "Must own all tokens");
            (string memory t, uint256 v) = getValue(tokens[i]);
            sum = sum + v;
            word = string(abi.encodePacked(word, t));
        }
        uint256 wordLength = bytes(word).length;
        if (wordLength < 4) {
            revert("Word must be greater than 3 letters");
        }
        if (wordLength > 8) {
            revert("Word must be less than 9 letters");
        }
        if (combinedWords[word]) {
            revert("Word already exists");
        }
        for (uint256 i = 1; i < tokens.length; i++) {
            _burn(tokens[i]);
            Combo storage oldCombo = combos[tokens[i]];

            combinedWords[oldCombo.word] = false;
            emit ComboDestroyed(msg.sender, oldCombo.word);

            oldCombo.word = "";
            oldCombo.points = 0;
            oldCombo.color = 0;
            
            emit MetadataUpdate(tokens[i]);
        }

        Combo storage combo = combos[tokens[0]];
        if (bytes(combo.word).length > 0) {
            // Remove Old Combo from Combined Words
            combinedWords[combo.word] = false;
            emit ComboDestroyed(msg.sender, combo.word);   
        }        

        combo.word = word;
        combo.points = sum;
        combo.color = utils.random(tokens[0], 1, 4);
        
        combinedWords[word] = true;
        emit ComboCreated(msg.sender, word, sum);
        emit MetadataUpdate(tokens[0]);
    }

    function getValue(uint256 tokenId)
        public
        view
        returns (string memory, uint256)
    {
        if (!_exists(tokenId)) {
            return ("", 0);
        } else if (bytes(combos[tokenId].word).length > 0) {
            return (combos[tokenId].word, combos[tokenId].points);
        } else {
            return utils.initValue(tokenId);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        bool burned;
        string memory word;
        uint256 points;
        uint256 color;

        uint256 wordLength = bytes(combos[tokenId].word).length;
        if (wordLength > 0) {
            word = combos[tokenId].word;
            points = combos[tokenId].points;
            color = combos[tokenId].color;
            burned = false;
        } else if (wordLength == 0 && !_exists(tokenId)) {
            word = "";
            burned = true;
        } else {
            (word, points) = utils.initValue(tokenId);
            color = 0;
            burned = false;
        }

        return renderer.getMetadata(segments, tokenId, word, points, color, burned);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function getMinutesRemaining() public view returns (uint256) {
        return utils.minutesRemaining(finalMintingBlock);
    }

    function mintCount() public view returns (uint256) {
        return _totalMinted();
    }

    function toggleCombinable() external onlyOwner {
        isCombinable = !isCombinable;
    }

    function updateSegmentsContract(address _address) external onlyOwner {
        segments = ISegments(_address);
    }

    function updatePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}