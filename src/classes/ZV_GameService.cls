public class ZV_GameService {  
	F45_DML_GenericDml genericDml;
	ZV_GamePlayerService gamePlayerService; 
	ZV_PlayerService playerService;
	ZVG_GameLookup gameLookup;
	ZVR_RobotPlayerHelper robotPlayerHelper;
 
	public ZV_GameService(
			F45_DML_GenericDml genericDml,
			ZV_GamePlayerService gamePlayerService, 
			ZV_PlayerService playerService, 
			ZVG_GameLookup gameLookup,
			ZVR_RobotPlayerHelper robotPlayerHelper
		) { 
		this.genericDml = genericDml;
		this.gamePlayerService = gamePlayerService;
		this.playerService = playerService;
		this.gameLookup = gameLookup;
		this.robotPlayerHelper = robotPlayerHelper;
	}

	public ZV_GameService() {
		this(
			new F45_DML_GenericDml(),  
			new ZV_GamePlayerService(),
			new ZV_PlayerService(),
			new ZVG_GameLookup(),
			new ZVR_RobotPlayerHelper()
		);
	}		
	
	private static String IN_PROGRESS = 'In Progress';
	
    public ZV_CellOccupyResult reactToOccupiedCell(ZV_GameContext gameContext) {
    	if (this.isInProgress(gameContext)) {
			this.gamePlayerService.findNextGamePlayer(gameContext);

			while(
					this.isInProgress(gameContext)
					&& this.playerService.isRobot(gameContext.nextPlayer) 
				) {
	    		gameContext.currentGamePlayer = gameContext.nextGamePlayer;
	    		gameContext.updatedCellList.addAll(this.robotPlayerHelper.maneuver(gameContext));
	    		this.gamePlayerService.findNextGamePlayer(gameContext);
			}
    	} 
		this.genericDml.doUpdate(gameContext.updatedCellList);    	  
		this.genericDml.doUpdate(new List<ZV_Game__c>{gameContext.game});
		return new ZV_CellOccupyResult(gameContext.updatedCellList, gameContext.game); 
    }

	public ZV_GameContext initializePlay (ZV_GameContext gameContext) {
    	if (gameContext.game.Status__c == 'New') {
			gameLookup.getFor(gameContext.game).initializePlay(gameContext);
			gameContext.game.Status__c = IN_PROGRESS;
			genericDml.doUpdate(gameContext.updatedCellList);
			genericDml.doUpdate(new List<ZV_Game__c>{gameContext.game});
    	}
		return gameContext;
	}

    public Boolean isInProgress(ZV_GameContext gameContext) {
    	return noGameWinner(gameContext)
    		&& noStalemate(gameContext)
    		&& gameContext.game.Status__c == IN_PROGRESS;
    }
    
    private Boolean noGameWinner(ZV_GameContext gameContext) {
    	this.gameLookup.getFor(gameContext.game).checkForWinner(gameContext);
    	return gameContext.game.Winner__c == null;
    } 
     
    private Boolean noStalemate(ZV_GameContext gameContext) {
    	this.gameLookup.getFor(gameContext.game).checkForStalemate(gameContext);
    	return gameContext.game.Status__c != 'Stalemate';
    } 
}