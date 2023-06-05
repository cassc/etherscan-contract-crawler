// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "erc721a/contracts/ERC721A.sol";

/**********************************************
 * In the beginning there was nothing,
 * and nothing we shall return to.
 * From nothing, we shall become something.
 * When something returns to nothing,
 * we shall become everything.
 **********************************************/

contract Nothing is ERC721A, IERC2981, Ownable {
    bool public something;
    bool public void;
    string public nowhere;
    address public nobody;
    uint256 public constant everything = 1001;
    mapping(address => bool) public conjurings;

    constructor() ERC721A("nothings", "NOTHING") {}

    /**
     * This is the way the universe begins.
     * This is the way the universe begins.
     * This is the way the universe begins.
     * Not with an explosion but with a key.
     */

    function becomeNothing() external {
        uint256 nothings = _totalMinted();

        require(msg.sender == tx.origin, "must be someone");
        require(something, "must be something");
        require(!conjurings[msg.sender], "something happened");
        require(nothings + 1 <= everything, "too much");

        _mint(msg.sender, 1);
        conjurings[msg.sender] = true;
    }

    /**
     * The key will set you free.
     * But not until it is finished with you.
     */

    function destroyNothing(uint256 tokenId) external {
        require(msg.sender == tx.origin, "must be someone");
        require(void, "reality is stable");

        _burn(tokenId, true);
    }

    /**
     * I am an invisible being.
     * No, I am not a ghost like those who haunted before me;
     * nor am I one of your ectoplasms.
     * I am a being of heavens—and I might even be said to possess everything.
     * I am invisible, understand, simply because people refuse to see me.
     */

    function fromSomethingToNothing(address someplace, uint256 some) external onlyOwner {
        uint256 nothings = _totalMinted();
        require(nothings + some <= everything, "too much");

        _mint(someplace, some);
    }

    function utNihilIncipere() external pure returns (string memory) {
        return "finem ut omnia";
    }

    function happen(bool _something) external onlyOwner {
        something = _something;
    }

    function somewhere(string calldata _nowhere) external onlyOwner {
        nowhere = _nowhere;
    }

    function someone(address _nobody) external onlyOwner {
        nobody = _nobody;
    }

    function distort(bool _void) external onlyOwner {
        void = _void;
    }

    function alchemy() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }

    function alchemize(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return nowhere;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "nothing there");
        return (nobody, (salePrice * 7) / 100);
    }

    /**
     * Homo sum, humani nihil a me alienum puto.
     */
}