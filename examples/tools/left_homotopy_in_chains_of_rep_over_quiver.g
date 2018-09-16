
# This example requires QPA2 in my devel2 branch in github: https://github.com/kamalsaleh/QPA2.git
LoadPackage( "QPA" );
LoadPackage( "ComplexesForCAP" );
LoadPackage( "ModelCategories" );
LoadPackage( "TriangulatedCategoriesForCAP");
LoadPackage( "RingsForHomalg" );
ReadPackage( "ModelCategories", "examples/tools/Triangulated_Structure.g" );

DeclareOperation( "LinearQuiver", [ IsDirection, IsObject, IsInt, IsInt ] );
DeclareOperation( "LinearRightQuiver", [ IsObject, IsInt, IsInt ] );
DeclareOperation( "LinearLeftQuiver", [ IsObject, IsInt, IsInt ] );
DeclareOperation( "ArrowsBetweenTwoVertices", [ IsVertex, IsVertex ] );

InstallMethod( LinearQuiver,
	[ IsDirection, IsObject, IsInt, IsInt ],
  function( d, k, m, n )
    local L, kL, c, l, constructor;
    if d = RIGHT then
      	constructor := "RightQuiver";
    else
        constructor := "LeftQuiver";
    fi;

    if m<=n then
    	L := ValueGlobal(constructor)(  Concatenation( "L(v", String(m), ")[d", String(m), "]" ), n - m + 1,
    		List( [ m .. n - 1 ], i-> [ Concatenation( "v", String(i) ), Concatenation( "v", String(i+1) ) ]  ) );
    	kL := PathAlgebra( k, L );
    	c := ArrowLabels( L );
    	l := List( [ 1 .. Length( c )-1 ], i -> [ c[i], c[i+1] ] );
	if d = RIGHT then
    	    l := List( l, label -> PrimitivePathByLabel( L, label[1] )*PrimitivePathByLabel( L, label[2] ) );
	else
	    l := List( l, label -> PrimitivePathByLabel( L, label[2] )*PrimitivePathByLabel( L, label[1] ) );
	fi;
    	l := List( l, r -> QuiverAlgebraElement( kL, [1], [r] ) );
    	return [ L, kL, l ];
    else
        L := ValueGlobal(constructor)(  Concatenation( "L(v", String(n), ")[d", String(n+1), "]" ), m - n + 1,
	        List( [ n .. m - 1 ], i-> [ Concatenation( "v", String(i+1) ), Concatenation( "v", String(i) ) ]  ) );
        kL := PathAlgebra( k, L );
	c := ArrowLabels( L );
	l := List( [ 1 .. Length( c )-1 ], i -> [ c[i+1], c[i] ] );
	if d = RIGHT then
	    l := List( l, label -> PrimitivePathByLabel( L, label[1] )*PrimitivePathByLabel( L, label[2] ) );
	else
	    l := List( l, label -> PrimitivePathByLabel( L, label[2] )*PrimitivePathByLabel( L, label[1] ) );
	fi;
	l := List( l, r -> QuiverAlgebraElement( kL, [1], [r] ) );
	L!.("m") := m;
	L!.("n") := n;
	return [ L, kL, l ];
    fi;
end );

InstallMethod( LinearRightQuiver,
	[ IsObject, IsInt, IsInt ],
  function( k, m, n )
    return LinearQuiver( RIGHT, k, m, n );
end );

InstallMethod( LinearLeftQuiver,
	[ IsObject, IsInt, IsInt ],
  function( k, m, n )
    return LinearQuiver( LEFT, k, m, n );
end );

InstallMethod( ArrowsBetweenTwoVertices,
		[ IsVertex, IsVertex ],
  function( v1, v2 )
    return Intersection( OutgoingArrows( v1 ), IncomingArrows( v2 ) );
end );

product_of_algebras := function( Aq, m, n )
    local k, Lmn, AL;
    k := LeftActingDomain( Aq );
    Lmn := LinearRightQuiver( k, m, n );
    if Lmn[3] = [ ] then
        AL := Lmn[2];
    else
        AL := QuotientOfPathAlgebra( Lmn[2], Lmn[3] );
    fi;
    return TensorProductOfAlgebras( AL, Aq );
end;

convert_chain_or_cochain_to_representation :=
    function( C, A  )
    local L, m, n, Q, dimension_vector, matrices1, matrices2, matrices;

    L := QuiverOfAlgebra( TensorProductFactors( A )[1] );
    m := ShallowCopy( Label( Vertex( L, 1 ) ) );
    RemoveCharacters( m, "v" );
    m := Int(m);
    n := m + NumberOfVertices( L ) - 1;
    if IsChainComplex( C ) then
        Q := QuiverOfAlgebra( A );
        dimension_vector := Concatenation( List( [ m .. n ], i-> DimensionVector( C[ i ] ) ) );
        matrices1 := Concatenation( List( [ m .. n ], i -> MatricesOfRepresentation( C[ i ] ) ) );
        matrices2 := Concatenation( List( [ m + 1 .. n ], i-> MatricesOfRepresentationHomomorphism( C^i ) ) );
        matrices := Concatenation( matrices1, matrices2 );
        return QuiverRepresentation( A, dimension_vector, Arrows( Q ), matrices );
    else
        Q := QuiverOfAlgebra( A );
        dimension_vector := Concatenation( List( [ m .. n ], i-> DimensionVector( C[ i ] ) ) );
        matrices1 := Concatenation( List( [ m .. n ], i -> MatricesOfRepresentation( C[ i ] ) ) );
        matrices2 := Concatenation( List( [ m .. n - 1 ], i-> MatricesOfRepresentationHomomorphism( C^i ) ) );
        matrices := Concatenation( matrices1, matrices2 );
        return QuiverRepresentation( A, dimension_vector, Arrows( Q ), matrices );
    fi;

end;

convert_chain_or_cochain_mor_to_representation_mor :=
    function( phi, A )
    local L,m,n, matrices, r1, r2;
    L := QuiverOfAlgebra( TensorProductFactors( A )[1] );
    m := ShallowCopy( Label( Vertex( L, 1 ) ) );
    RemoveCharacters( m, "v" );
    m := Int(m);
    n := m + NumberOfVertices( L ) - 1;
    matrices := Concatenation( List( [ m .. n ], i -> MatricesOfRepresentationHomomorphism( phi[ i ] ) ) );
    r1 := convert_chain_or_cochain_to_representation( Source( phi ), A );
    r2 := convert_chain_or_cochain_to_representation( Range( phi ), A );
    return QuiverRepresentationHomomorphism( r1, r2, matrices );
end;


convert_rep_mor_to_complex_mor :=
    function( C1, C2, mor, A )
    local Q, L, q, m, n, mats;
    # Do the compatibility stuff
    Q := QuiverOfAlgebra( A );
    L := QuiverOfAlgebra( TensorProductFactors( A )[1] );
    q := QuiverOfAlgebra( TensorProductFactors( A )[2] );
    m := ShallowCopy( Label( Vertex( L, 1 ) ) );
    RemoveCharacters( m, "v" );
    m := Int(m);
    n := m + NumberOfVertices( L ) - 1;
#     maps := MatricesOfRepresentationHomomorphism( mor );
    mats := MatricesOfRepresentationHomomorphism( mor );
    mats := List( [ 1 .. NumberOfVertices( L ) ],
                i -> List( [ 1 .. NumberOfVertices( q ) ],
                        j-> mats[ (i-1)*NumberOfVertices( q ) + j ] ) );
    mats := List( [ m .. n ], k -> QuiverRepresentationHomomorphism( C1[k], C2[k], mats[k-m+1] ) );
    if IsChainComplex( C1 ) then
        return ChainMorphism( C1, C2, mats, m );
    else
        return CochainMorphism( C1, C2, mats, m );
    fi;
end;

generators_of_hom_for_chains_of_quiver_reps :=
    function( C1, C2 )
    local m, n, A, R1, R2, B;

    m := Minimum( ActiveLowerBound( C1 ), ActiveLowerBound( C2 ) ) + 1;
    n := Maximum( ActiveUpperBound( C1 ), ActiveUpperBound( C2 ) ) - 1;
    if IsChainComplex( C1 ) then
        A := product_of_algebras( AlgebraOfRepresentation( C1[m] ), n, m );
    else
        A := product_of_algebras( AlgebraOfRepresentation( C1[m] ), m, n );
    fi;
    R1 := convert_chain_or_cochain_to_representation( C1, A );
    R2 := convert_chain_or_cochain_to_representation( C2, A );
    B := BasisOfHom( R1, R2 );
    return List( B, mor -> convert_rep_mor_to_complex_mor( C1, C2, mor, A ) );
end;

compute_lift_in_quiver_rep :=
    function( f, g )
    local homs_basis, Q, k, V, homs_basis_composed_with_g, L, vector, mat, sol, lift, h;

    if IsZeroForObjects( Range( f ) ) then
        return ZeroMorphism( Source( f ), Source( g ) );
    fi;

    homs_basis := BasisOfHom( Source( f ), Source( g ) );
    # if homs_basis = [] then there is only the zero morphism between source(f) and source(g)
    # Thus f must be zero in order for lift to exist.
    if homs_basis = [ ] then
      if IsZeroForMorphisms( f ) then
        return ZeroMorphism( Source( f ), Source( g ) );
      else
        return fail;
      fi;
    fi;
    Q := QuiverOfRepresentation( Source( f ) );
    k := LeftActingDomain( AlgebraOfRepresentation( Source( f ) ) );
    V := Vertices( Q );
    homs_basis_composed_with_g := List( homs_basis, m -> PreCompose( m, g ) );
    L := List( V, v -> Concatenation( [ RightMatrixOfLinearTransformation( MapForVertex( f, v ) ) ],
                                        List( homs_basis_composed_with_g, h -> RightMatrixOfLinearTransformation( MapForVertex( h, v ) ) ) ) );
    L := Filtered( L, l -> ForAll( l, m -> not IsZero( DimensionsMat( m )[ 1 ]*DimensionsMat( m )[ 2 ] ) ) );
    L := List( L, l ->  List( l, m -> MatrixByCols( k, [ Concatenation( ColsOfMatrix( m ) ) ] ) ) );

    L := List( TransposedMat( L ), l -> StackMatricesVertically( l ) );
    vector := StandardVector( k, ColsOfMatrix( L[ 1 ] )[ 1 ] );
    mat := TransposedMat( StackMatricesHorizontally( List( [ 2 .. Length( L ) ], i -> L[ i ] ) ) );

    sol := SolutionMat( mat, vector );

    if sol = fail then
        return fail;
    else

    sol := ShallowCopy( AsList( sol ) );

    lift := ZeroMorphism( Source( f ), Source( g ) );
    for h in homs_basis do
         if not IsZero( sol[ 1 ] ) then
             lift := lift + sol[ 1 ]*h;
         fi;
    Remove( sol, 1 );
    od;
    fi;
    return lift;
end;

compute_colift_in_quiver_rep :=
    function( f, g )
    local homs_basis, Q, k, V, homs_basis_composed_with_f, L, vector, mat, sol, colift, h;

    homs_basis := BasisOfHom( Range( f ), Range( g ) );
    # if homs_basis = [] then there is only the zero morphism between range(f) and range(g)
    # Thus g must be zero in order for colift to exist.
    if homs_basis = [ ] then
      if IsZeroForMorphisms( g ) then
	return ZeroMorphism( Range( f ), Range( g ) );
      else
	return fail;
      fi;
    fi;
    Q := QuiverOfRepresentation( Source( f ) );
    k := LeftActingDomain( AlgebraOfRepresentation( Source( f ) ) );
    V := Vertices( Q );
    homs_basis_composed_with_f := List( homs_basis, m -> PreCompose( f, m ) );
    L := List( V, v -> Concatenation( [ RightMatrixOfLinearTransformation( MapForVertex( g, v ) ) ],
                                        List( homs_basis_composed_with_f, h -> RightMatrixOfLinearTransformation( MapForVertex( h, v ) ) ) ) );
    # this line is added because I get errors when MatrixByCols recieve empty matrix
    # it is still true since i only delete zero matrices from the equation system.
    L := Filtered( L, l -> ForAll( l, m -> not IsZero( DimensionsMat( m )[ 1 ]*DimensionsMat( m )[ 2 ] ) ) );
    L := List( L, l ->  List( l, m -> MatrixByCols( k, [ Concatenation( ColsOfMatrix( m ) ) ] ) ) );

    L := List( TransposedMat( L ), l -> StackMatricesVertically( l ) );
    vector := StandardVector( k, ColsOfMatrix( L[ 1 ] )[ 1 ] );
    mat := TransposedMat( StackMatricesHorizontally( List( [ 2 .. Length( L ) ], i -> L[ i ] ) ) );
    sol := SolutionMat( mat, vector );

    if sol = fail then
     return fail;
    else
    sol := ShallowCopy( AsList( sol ) );
    colift := ZeroMorphism( Range( f ), Range( g ) );
    for h in homs_basis do
        if not IsZero( sol[ 1 ] ) then
            colift := colift + sol[ 1 ]*h;
        fi;
    Remove( sol, 1 );
    od;

    fi;
    return colift;
end;


dual_functor :=
    function( cat )
    local A, Q, A_op, Q_op, cat_op, dual, cat_of_op_quiver;

    cat_op := Opposite( cat );
    A := AlgebraOfCategory( cat );
    Q := QuiverOfAlgebra( A );
    A_op := OppositeAlgebra( A );
    Q_op := QuiverOfAlgebra( A_op );
    cat_of_op_quiver := CategoryOfQuiverRepresentations( A_op );
    dual := CapFunctor( "Dual functor", cat_op, cat_of_op_quiver );
    AddObjectFunction( dual,
        function( r )
        return QuiverRepresentation( A_op, DimensionVector( Opposite(r) ), Arrows( Q_op ), List( MatricesOfRepresentation( Opposite(r) ), TransposedMat ) );
        end );
    AddMorphismFunction( dual,
        function( new_source, phi, new_range )
        return QuiverRepresentationHomomorphism( new_source, new_range, List( MatricesOfRepresentationHomomorphism( Opposite( phi ) ), TransposedMat ) );
        end );
    return dual;
end;

compute_lifts_in_complexes_of_quiver_reps :=
    function( f, g )
    local m, n, A, f_, g_, lift;
    m := Minimum( ActiveLowerBound( Source(f) ), ActiveLowerBound( Source(g) ) ) + 1;
    n := Maximum( ActiveUpperBound( Source(f) ), ActiveUpperBound( Source(g) ) ) - 1;

    if IsChainMorphism( f ) then
        A := product_of_algebras( AlgebraOfRepresentation( Source(f[ m ]) ), n, m );
    else
        A := product_of_algebras( AlgebraOfRepresentation( Source(f[ m ]) ), m, n );
    fi;

    f_ := convert_chain_or_cochain_mor_to_representation_mor( f, A );
    g_ := convert_chain_or_cochain_mor_to_representation_mor( g, A );

    lift := Lift( f_, g_ );

    if lift = fail then
        return fail;
    else
        return convert_rep_mor_to_complex_mor( Source(f), Source( g ), lift, A );
    fi;
end;

compute_colifts_in_complexes_of_quiver_reps :=
    function( f, g )
    local m, n, A, f_, g_, colift;
    m := Minimum( ActiveLowerBound( Range(f) ), ActiveLowerBound( Range(g) ) ) + 1;
    n := Maximum( ActiveUpperBound( Range(f) ), ActiveUpperBound( Range(g) ) ) - 1;

    if IsChainMorphism( f ) then
        A := product_of_algebras( AlgebraOfRepresentation( Source(f[ m ]) ), n, m );
    else
        A := product_of_algebras( AlgebraOfRepresentation( Source(f[ m ]) ), m, n );
    fi;

    f_ := convert_chain_or_cochain_mor_to_representation_mor( f, A );
    g_ := convert_chain_or_cochain_mor_to_representation_mor( g, A );

    colift := Colift( f_, g_ );

    if colift = fail then
        return fail;
    else
        return convert_rep_mor_to_complex_mor( Range(f), Range( g ), colift, A );
    fi;
end;

BeilinsonQuiverWithRelations := function( field, n )
local i,j,u,v,arrows,kQ,AQ,Q;
u := "";
for i in [ 1 .. n ] do
for j in [ 0 .. n ] do
u := Concatenation( u,"x",String(i),String(j),":",String(i),"->",String(i+1),"," );
od;
od;
Remove( u, Length( u ) );
u := Concatenation( "Q(", String(n+1),")[",u,"]" );
Q := RightQuiver( u );
arrows := Arrows( Q );
kQ := PathAlgebra( field, Q );
v := [ ];
for i in [ 1 .. n-1 ] do
for j in Combinations( [ 0 .. n ], 2 ) do
Add( v, kQ.(Concatenation( "x", String(i),String(j[1])) )* kQ.(Concatenation( "x", String(i+1),String(j[2]) ) )-
        kQ.(Concatenation( "x",String(i),String(j[2]) ) )* kQ.(Concatenation( "x", String(i+1),String(j[1]) ) ) );
od;
od;
AQ := QuotientOfPathAlgebra( kQ, v );
return [Q,kQ,AQ];
end;

