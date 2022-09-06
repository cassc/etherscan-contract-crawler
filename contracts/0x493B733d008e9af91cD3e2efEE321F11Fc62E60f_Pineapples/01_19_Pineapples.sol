// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @entity: Pinaverse
/// @author: Wizard

/*
       ____  _                                     
      / __ \(_)___  ____ __   _____  _____________ 
     / /_/ / / __ \/ __ `/ | / / _ \/ ___/ ___/ _ \
    / ____/ / / / / /_/ /| |/ /  __/ /  (__  )  __/
   /_/   /_/_/ /_/\__,_/ |___/\___/_/  /____/\___/ 

*/

import "../token/WizardsERC721A.sol";

error MustApproveContract();
error MustBeOwner();
error PaymentFailed();
error TooManyForRequest();
error MustSetPinaverse();

contract Pineapples is WizardsERC721A {
    IERC1155 private juice;
    IERC721 private op;

    address private _pinaverse;
    uint256 private _swapPrice;
    mapping(uint256 => bool) private _hasReceivedJuice;

    constructor(
        string memory baseTokenURI,
        string memory contractURI,
        address royaltyRecipient,
        uint24 royaltyValue,
        uint256 swapPrice_,
        address juice_,
        address op_
    )
        WizardsERC721A(
            "Pinaverse Pineapples",
            "p",
            baseTokenURI,
            contractURI,
            royaltyRecipient,
            royaltyValue,
            _msgSender()
        )
    {
        _swapPrice = swapPrice_;
        juice = IERC1155(juice_);
        op = IERC721(op_);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 3556;
    }

    function getPinaverseAddress() public view returns (address) {
        return _pinaverse;
    }

    function setSwapPrice(uint256 swapPrice_) public isAdmin {
        _swapPrice = swapPrice_;
    }

    function hasReceivedJuice(uint256 id) public view returns (bool) {
        return _hasReceivedJuice[id];
    }

    function getSwapPrice() public view returns (uint256) {
        return _swapPrice;
    }

    function swap(uint256 id) public payable whenNotPaused {
        if (msg.value != _swapPrice) {
            revert PaymentFailed();
        }
        if (!op.isApprovedForAll(_msgSender(), address(this))) {
            revert MustApproveContract();
        }

        _swap(_msgSender(), id);

        if (_hasReceivedJuice[id] == true) return;
        _hasReceivedJuice[id] = true;
        _mintJuice(_msgSender(), 1);
    }

    function swapBatch(uint256[] memory ids) public payable whenNotPaused {
        if (ids.length > 10) revert TooManyForRequest();
        uint256 qtyToSwap = ids.length;
        uint256 juiceToMint = ids.length;

        unchecked {
            uint256 totalSwapPrice = qtyToSwap * _swapPrice;
            if (msg.value != totalSwapPrice) revert PaymentFailed();
        }

        if (!op.isApprovedForAll(_msgSender(), address(this))) {
            revert MustApproveContract();
        }

        for (uint256 i = 0; i < qtyToSwap; i++) {
            _swap(_msgSender(), ids[i]);
            if (_hasReceivedJuice[ids[i]] == true) {
                juiceToMint--;
            }
            _hasReceivedJuice[ids[i]] = true;
        }

        _mintJuice(_msgSender(), juiceToMint);
    }

    function exit(uint256 id) public whenNotPaused {
        if (ownerOf(id) != _msgSender()) revert MustBeOwner();
        if (isApprovedForAll(_msgSender(), address(this))) {
            revert MustApproveContract();
        }

        _burn(id);
        op.transferFrom(address(this), _msgSender(), id);
    }

    function _swap(address from, uint256 id) internal virtual {
        if (op.ownerOf(id) != from) revert MustBeOwner();

        op.transferFrom(from, address(this), id);
        _mintById(from, id, "", false);
    }

    function _mintJuice(address to, uint256 amount) internal virtual {
        if (juice.allowRandom()) juice.randomMint(to, amount);
        else juice.mint(to, 0, amount);
    }

    function setPinaverse(address pinaverse) external isAdmin {
        _pinaverse = pinaverse;
    }

    function withdraw() external isAdmin {
        if (_pinaverse == address(0)) revert MustSetPinaverse();
        payable(_pinaverse).transfer(address(this).balance);
    }

    function withdrawToken(address token) external isAdmin {
        if (_pinaverse == address(0)) revert MustSetPinaverse();
        IERC20 erc20 = IERC20(token);
        erc20.transfer(_pinaverse, erc20.balanceOf(address(this)));
    }

    receive() external payable {}
}

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IERC1155 {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function randomMint(address to, uint256 quantity) external;

    function allowRandom() external view returns (bool);
}