##########################################################
# HomotopyCategories                    Kamal Saleh
#
# Gap packages                       siegen, 2017
#
##########################################################

DeclareRepresentation( "IsHomotopyCapCategoryObjectRep",
                        IsComponentObjectRep and IsAttributeStoringRep,
                        [ ] );
                        
DeclareRepresentation( "IsHomotopyCapCategoryMorphismRep",
                        IsComponentObjectRep and IsAttributeStoringRep,
                        [ ] );
                        
BindGlobal( "FamilyOfHomotopyCapCategoryObjects", 
             NewFamily( "model categories objects" ) );
             
BindGlobal( "FamilyOfHomotopyCapCategoryMorphisms", 
             NewFamily( "model categories morphisms" ) );
             
BindGlobal( "TheTypeOfHomotopyCapCategoryObject",
             NewType( FamilyOfHomotopyCapCategoryObjects,
                      IsHomotopyCapCategoryObject and IsHomotopyCapCategoryObjectRep ) );
                      
BindGlobal( "TheTypeOfHomotopyCapCategoryMorphism",
             NewType( FamilyOfHomotopyCapCategoryMorphisms,
                      IsHomotopyCapCategoryMorphism and IsHomotopyCapCategoryMorphismRep ) );
                      
###
InstallMethod( HomotopyCategory, 
               [ IsCapCategory and IsModelCategory ],
    function( cat )
    local homotopy_category, to_be_finalized;
    
    homotopy_category := CreateCapCategory( Concatenation( "Homotopy category of ", Big_to_Small( Name( cat ) ) ) );

    SetUnderlyingModelCategory( homotopy_category, cat );
    
    INSTALL_METHODS_FOR_HOMOTOPY_CATEGORIES( homotopy_category );
    
    to_be_finalized := ValueOption( "FinalizeCategory" );
   
    if to_be_finalized = true then
      
       Finalize( homotopy_category );
      
    fi;
    
    return homotopy_category;
    
end );

##
InstallMethod( AsObjectInHomotopyCategory, 
               [ IsCapCategoryObject ],
    function( obj )
    local A;
    
    A := rec( );
    
    ObjectifyWithAttributes( A, TheTypeOfHomotopyCapCategoryObject,
                             UnderlyingObject, obj );
                             
    AddObject( HomotopyCategory( CapCategory( obj ) ), A );
    
    return A;
    
end );

##
InstallMethod( AsMorphismInHomotopyCategory, 
               [ IsCapCategoryMorphism ],
    function( morphism )
    local phi;
    
    phi := rec( );
    
    ObjectifyWithAttributes( phi, TheTypeOfHomotopyCapCategoryMorphism,
                             UnderlyingMorphism, morphism,
                             Source, AsObjectInHomotopyCategory( Source( morphism ) ),
                             Range, AsObjectInHomotopyCategory( Range( morphism ) )  );
    
    AddMorphism( HomotopyCategory( CapCategory( morphism ) ), phi );
    
    return phi;
    
end );

##
InstallMethod( AsMorphismInHomotopyCategoryByReplacement, 
               [ IsCapCategoryObject, IsCapCategoryMorphism, IsCapCategoryObject ],
    function( M, morphism, N )
    local phi;
    
    if not IsEqualForObjects( Source( morphism ), FibrantModel( CofibrantModel( M ) ) ) or
        not IsEqualForObjects( Range( morphism ), FibrantModel( CofibrantModel( N ) ) ) then
            Error( "Input is not compatible" );
    fi;
    
    phi := rec( );
    
    ObjectifyWithAttributes( phi, TheTypeOfHomotopyCapCategoryMorphism,
                             UnderlyingReplacement, morphism,
                             Source, AsObjectInHomotopyCategory( M ),
                             Range, AsObjectInHomotopyCategory( N )  );
    
    AddMorphism( HomotopyCategory( CapCategory( morphism ) ), phi );
    
    return phi;
    
end );

##
InstallMethod( UnderlyingReplacement,
               [ IsHomotopyCapCategoryCell and IsCapCategoryObject ],
    function( obj )

    return FibrantModel( CofibrantModel( UnderlyingObject( obj ) ) );

end );

##
InstallMethod( UnderlyingReplacement,
               [ IsHomotopyCapCategoryCell and IsCapCategoryMorphism ],
    function( morphism )

    return MorphismBetweenFibrantModels( MorphismBetweenCofibrantModels( UnderlyingMorphism( morphism ) ) );

end );

InstallGlobalFunction( INSTALL_METHODS_FOR_HOMOTOPY_CATEGORIES,
    function( homotopy_category )
    local is_equal_for_morphisms, cat;
    
    cat := UnderlyingModelCategory( homotopy_category );
    
    if CanCompute( cat, "AreLeftHomotopic" ) then
       is_equal_for_morphisms := 
            function( morphism1, morphism2 )
                return AreLeftHomotopic( morphism1, morphism2 );
            end;
    elif CanCompute( cat, "AreRightHomotopic" ) then
       is_equal_for_morphisms := 
            function( morphism1, morphism2 )
                return AreRightHomotopic( morphism1, morphism2 );
            end;
    else
        
        Error( "We can not decide equality between two morphisms" );
       
    fi;

    # IsEqualForObjects
    AddIsEqualForObjects( homotopy_category,
        function( obj1, obj2 )
            return IsEqualForObjects( UnderlyingObject( obj1 ), UnderlyingObject( obj2 ) );
        end );
    # IsEqualForMorphisms
    AddIsEqualForMorphisms( homotopy_category,
        function( morphism1, morphism2 )
        return is_equal_for_morphisms( UnderlyingMorphism( morphism1 ), UnderlyingMorphism( morphism2 ) );
        end );
        
    # Methods on morphisms
    AddPreCompose( homotopy_category, 
        function( morphism1, morphism2 )
        local morphism;
        
        if HasUnderlyingMorphism( morphism1 ) and HasUnderlyingMorphism( morphism2 ) then
            morphism := PreCompose( UnderlyingMorphism( morphism1 ), UnderlyingMorphism( morphism2 ) );
            AddToToDoList( ToDoListEntry( [ [ morphism1, "UnderlyingReplacement" ], [ morphism2, "UnderlyingReplacement" ]  ],
                                        function( )
                                        if not HasUnderlyingReplacement( morphism ) then
                                            SetUnderlyingReplacement( morphism, PreCompose( UnderlyingReplacement( morphism1 ), UnderlyingReplacement( morphism2 ) ) );
                                        fi;
                                        end ) );
            return AsMorphismInHomotopyCategory( morphism );
        else
            morphism := PreCompose( UnderlyingReplacement( morphism1 ), UnderlyingReplacement( morphism2 ) );
            return AsMorphismInHomotopyCategoryByReplacement(
                UnderlyingObject( Source( morphism1 ) ), morphism, UnderlyingObject( Range( morphism2 ) )
            );
        fi;
    end );

    
    ## IdentityMorphisms
    AddIdentityMorphism( homotopy_category,

      function( object )

        return AsMorphismInHomotopyCategory( IdentityMorphism( UnderlyingObject( object ) ) );

    end );

    ## Addition for morphisms
    AddAdditionForMorphisms( homotopy_category,

      function( morphism1, morphism2 )
        local sum;

        sum := AdditionForMorphisms( UnderlyingMorphism( morphism1 ),
                                     UnderlyingMorphism( morphism2 ) );

        return AsMorphismInHomotopyCategory( sum );

    end );

    ## IsZeroForMorphisms
    AddIsZeroForMorphisms( homotopy_category, 

       function( morphism )
       local underlying_mor;

       underlying_mor := UnderlyingMorphism( morphism );

       if HasIsZero( underlying_mor ) and IsZero( underlying_mor ) then

          return true;

       else 

          return is_equal_for_morphisms( underlying_mor, ZeroMorphism( Source( underlying_mor ), Range( underlying_mor ) ) );

       fi;

    end );

    ## IsZeroForObjects
    AddIsZeroForObjects( homotopy_category, 

    function( obj )
    local underlying_obj;

       underlying_obj := UnderlyingObject( obj );

       if HasIsZero( underlying_obj ) and IsZero( underlying_obj ) then

          return true;

       else 

          return IsZero( IdentityMorphism( obj ) );

       fi;

    end );

    ## Additive inverse for morphisms
    AddAdditiveInverseForMorphisms( homotopy_category,

      function( morphism )
        local new_mor;

        new_mor := AdditiveInverseForMorphisms( UnderlyingMorphism( morphism ) );

        return AsMorphismInHomotopyCategory( new_mor );

    end );

    ## Zero morphism
    AddZeroMorphism( homotopy_category,

      function( source, range )
        local zero_mor;

        zero_mor := ZeroMorphism( UnderlyingObject( source ), UnderlyingObject( range ) );

        return AsMorphismInHomotopyCategory( zero_mor );

    end );
    
    ## isomorphism
    AddIsIsomorphism( homotopy_category,
        function( mor )
        if HasUnderlyingMorphism( mor ) then
            return IsWeakEquivalence( UnderlyingMorphism( mor ) );
        else
        
            return IsWeakEquivalence( UnderlyingReplacement( mor ) );
        fi;
        end );
        
    ## Inverse
     AddInverse( homotopy_category, 
         function( mor )
         local f, A, B, q, p, C, r, s, sr;
         
         f := UnderlyingReplacement( mor );
         
         A := Source( f );
         
         B := Range( f );
         
         q := FactorThroughAcyclicCofibration( f )[ 1 ];
         
         p := FactorThroughAcyclicCofibration( f )[ 2 ];
 
         C := Range( q );
         
         Assert( 5, IsWeakEquivalence( p ) );
         
         # Axiom
         SetIsWeakEquivalence( p, true );
         
         r := Lifting( q, UniversalMorphismIntoTerminalObject( A ), IdentityMorphism( A ), UniversalMorphismIntoTerminalObject( C ) );
         
         s := Lifting( UniversalMorphismFromInitialObject( B ), p, UniversalMorphismFromInitialObject( C ), IdentityMorphism( B ) );
         
         # this is wrong, the output here is not in the correct category
         # corrected, but there is maybe a better way ..
         return AsMorphismInHomotopyCategoryByReplacement( UnderlyingObject( Range( mor ) ), PreCompose( s, r ), UnderlyingObject( Source( mor ) ) );
         
         end );
         
    ## Zero object
    AddZeroObject( homotopy_category,

        function( )
        local zero_obj;
        
        zero_obj := ZeroObject( UnderlyingCategory( homotopy_category ) );
        
        return AsObjectInHomotopyCategory( zero_obj );
        
    end );
    
    ## 
    
    ## direct sum
    AddDirectSum( homotopy_category,
      
      function( obj_list )
        local underlying_list, underlying_sum;
        
        underlying_list := List( obj_list, UnderlyingObject );
        
        underlying_sum := CallFuncList( DirectSum, underlying_list );
        
        return AsObjectInHomotopyCategory( underlying_sum );
        
    end );
    
    AddDirectSumFunctorialWithGivenDirectSums( homotopy_category, 
        function( source, L, range )
        local maps, morphism;
        
        maps := List( L, i-> UnderlyingMorphism( i ) );
        
        morphism := DirectSumFunctorial( maps );
        
        return AsMorphismInHomotopyCategory( morphism );
        
    end );
    
    AddInjectionOfCofactorOfDirectSum( homotopy_category,
        function( L, n )
        local underlying_list, i;
        
        underlying_list := List( L, i-> UnderlyingObject( i ) );
        
        i := InjectionOfCofactorOfDirectSum( underlying_list, n );
        
        return AsMorphismInHomotopyCategory( i );
        
    end );
    
    AddProjectionInFactorOfDirectSum( homotopy_category,
        function( L, n )
        local underlying_list, i;
        
        underlying_list := List( L, i-> UnderlyingObject( i ) );
        
        i := ProjectionInFactorOfDirectSum( underlying_list, n );
        
        return AsMorphismInHomotopyCategory( i );
        
    end );
    
    AddUniversalMorphismIntoDirectSum( homotopy_category, 
        function( objects_list, morphisms_list  )
        local underlying_list, morphism;
        
        underlying_list := List( morphisms_list, i -> UnderlyingMorphism( i ) );
        
        morphism := UniversalMorphismIntoDirectSum( underlying_list );
        
        return AsMorphismInHomotopyCategory( morphism );
        
        end );
    
    AddUniversalMorphismFromDirectSum( homotopy_category, 
        function( objects_list, morphisms_list )
        local underlying_list, morphism;
        
        underlying_list := List( morphisms_list, i -> UnderlyingMorphism( i ) );
        
        morphism := UniversalMorphismFromDirectSum( underlying_list );
        
        return AsMorphismInHomotopyCategory( morphism );
        
        end );
    
end );