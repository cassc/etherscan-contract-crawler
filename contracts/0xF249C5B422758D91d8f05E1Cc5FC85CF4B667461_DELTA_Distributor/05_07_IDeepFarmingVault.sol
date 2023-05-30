pragma abicoder v2;

struct RecycleInfo {
    uint256 booster;
    uint256 farmedDelta;
    uint256 farmedETH;
    uint256 recycledDelta;
    uint256 recycledETH;
}



interface IDeepFarmingVault {
    function addPermanentCredits(address,uint256) external;
    function addNewRewards(uint256 amountDELTA, uint256 amountWETH) external;
    function adminRescueTokens(address token, uint256 amount) external;
    function setCompundBurn(bool shouldBurn) external;
    function compound(address person) external;
    function exit() external;
    function withdrawRLP(uint256 amount) external;
    function realFarmedOfPerson(address person) external view returns (RecycleInfo memory);
    function deposit(uint256 numberRLP, uint256 numberDELTA) external;
    function depositFor(address person, uint256 numberRLP, uint256 numberDELTA) external;
    function depositWithBurn(uint256 numberDELTA) external;
    function depositForWithBurn(address person, uint256 numberDELTA) external;
}