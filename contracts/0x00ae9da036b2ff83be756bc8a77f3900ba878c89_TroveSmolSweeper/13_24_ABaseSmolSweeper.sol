// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//           _____                    _____                   _______                   _____            _____                    _____                    _____                    _____
//          /\    \                  /\    \                 /::\    \                 /\    \          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\____\               /::::\    \               /::\____\        /::\    \                /::\____\                /::\    \                /::\    \
//        /::::\    \              /::::|   |              /::::::\    \             /:::/    /       /::::\    \              /:::/    /               /::::\    \              /::::\    \
//       /::::::\    \            /:::::|   |             /::::::::\    \           /:::/    /       /::::::\    \            /:::/   _/___            /::::::\    \            /::::::\    \
//      /:::/\:::\    \          /::::::|   |            /:::/~~\:::\    \         /:::/    /       /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/|::|   |           /:::/    \:::\    \       /:::/    /       /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/__\:::\    \
//     \:::\   \:::\    \      /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /        \:::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \
//   ___\:::\   \:::\    \    /:::/  |::|___|______   /:::/____/   \:::\____\   /:::/    /       ___\:::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \  /:::/   |::::::::\    \ |:::|    |     |:::|    | /:::/    /       /\   \:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\/:::/    |:::::::::\____\|:::|____|     |:::|    |/:::/____/       /::\   \:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    /\::/    / ~~~~~/:::/    / \:::\    \   /:::/    / \:::\    \       \:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/  \/____/      /:::/    /   \:::\    \ /:::/    /   \:::\    \       \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \                  /:::/    /     \:::\    /:::/    /     \:::\    \       \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /            \::::::/    /
//    \:::\   \:::\____\                /:::/    /       \:::\__/:::/    /       \:::\    \       \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /              \::::/    /
//     \:::\  /:::/    /               /:::/    /         \::::::::/    /         \:::\    \       \:::\  /:::/    /        \:::\__/:::/    /               /:::/    /                \::/____/
//      \:::\/:::/    /               /:::/    /           \::::::/    /           \:::\    \       \:::\/:::/    /          \::::::::/    /               /:::/    /                  ~~
//       \::::::/    /               /:::/    /             \::::/    /             \:::\    \       \::::::/    /            \::::::/    /               /:::/    /
//        \::::/    /               /:::/    /               \::/____/               \:::\____\       \::::/    /              \::::/    /               /:::/    /
//         \::/    /                \::/    /                 ~~                      \::/    /        \::/    /                \::/____/                \::/    /
//          \/____/                  \/____/                                           \/____/          \/____/                  ~~                       \/____/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../token/ANFTReceiver.sol";

error InvalidNFTAddress();
error FirstBuyReverted(bytes message);
error AllReverted();

abstract contract ABaseSmolSweeper is Ownable, ANFTReceiver, ERC165 {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_BASIS_POINTS = 1_000_000;
    // uint256 public constant MINIMUM_SWEEP_AMOUNT_FOR_FEE = 1_000_000;
    uint256 public sweepFee = 0;

    function _calculateFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * sweepFee) / FEE_BASIS_POINTS;
    }

    function calculateFee(uint256 _amount) external view returns (uint256) {
        return _calculateFee(_amount);
    }

    function _calculateAmountWithoutFees(uint256 _amountWithFee)
        internal
        view
        returns (uint256)
    {
        return ((_amountWithFee * FEE_BASIS_POINTS) /
            (FEE_BASIS_POINTS + sweepFee));
    }

    function calculateAmountAmountWithoutFees(uint256 _amountWithFee)
        external
        view
        returns (uint256)
    {
        return _calculateAmountWithoutFees(_amountWithFee);
    }

    function _setFee(uint256 _fee) internal {
        sweepFee = _fee;
    }

    function setFee(uint256 _fee) external onlyOwner {
        _setFee(_fee);
    }

    function _approveERC20TokenToContract(
        IERC20 _token,
        address _contract,
        uint256 _amount
    ) internal {
        _token.safeApprove(address(_contract), uint256(_amount));
    }

    function approveERC20TokenToContract(
        IERC20 _token,
        address _contract,
        uint256 _amount
    ) external onlyOwner {
        _approveERC20TokenToContract(_token, _contract, _amount);
    }

    // rescue functions
    // those have not been tested yet
    function transferETHTo(address payable _to, uint256 _amount)
        external
        onlyOwner
    {
        _to.transfer(_amount);
    }

    function transferERC20TokenTo(
        IERC20 _token,
        address _address,
        uint256 _amount
    ) external onlyOwner {
        _token.safeTransfer(address(_address), uint256(_amount));
    }

    function transferERC721To(
        IERC721 _token,
        address _to,
        uint256 _tokenId
    ) external onlyOwner {
        _token.safeTransferFrom(address(this), _to, _tokenId);
    }

    function transferERC1155To(
        IERC1155 _token,
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external onlyOwner {
        _token.safeBatchTransferFrom(
            address(this),
            _to,
            _tokenIds,
            _amounts,
            _data
        );
    }
}