interface ITransferFrom {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

interface ITransferFromAndBurnFrom is ITransferFrom {
    function burnFrom(address account, uint256 amount) external;
}